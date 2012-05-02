class ItemTemplate < ActiveRecord::Base
  acts_as_superclass
  attr_accessible :lat, :lng
	belongs_to :item, :polymorphic => true
	has_many :categories, :through => :categoryholders
	has_many :notification
	has_many :users, :through => :subscriptions	
	has_many :response_templates
	#validates :user_id, :presence => true
    validates :title, :presence => true
    validates :location, :presence => true 
	scope :followed, lambda{|key| {:conditions => {:id => key}}}
	scope :has_category,       lambda{ |n| { :conditions => { :categories_id => n}}}
	scope :has_title, lambda{|name| {:conditions => ["title LIKE ? OR title LIKE ? OR title LIKE ?", "% " + name + " %", name, name + " %"]}}
	scope :keyword, lambda{|key| {:conditions => ["title LIKE ? OR title LIKE ? OR title LIKE ? OR description LIKE ? OR description LIKE ? OR description LIKE ?", "% " + key + " %", key, key + " %", "% " + key + " %", key, key + " %" ]}}
	
	def category_id
      return cat_id
	end
	
	def generate_content
		contentHash = {}
	    contentHash.add("title"=>title)
		contentHash.add("location"=>location)
		contentHash.add("description"=>description)
		contentHash.add("created_at"=>created_at)
		contentHash.add("updated_at"=>updated_at)
		contentHash.add("update_time"=>update_time)
		contentHash.add("popularity"=>popularity)
		contentHash.add("cat_name"=>Category.find(cat_id))
		contentHash.add("type"=>type)
		hash = {}
		case type
			when "question"
				hash =Question.find(item_id).generate_content
			when "event"
				hash = Event.find(item_id).generate_content
			when "challenge"
				hash = Challenge.find(item_id).generate_content
			when "project"
				hash = Project.find(item_id).generate_content
			when "group"
				hash = Group.find(item_id).generate_content
			end
		return contentHash.merge(hash)
	end

	def create_subscription(subscriber)
		subscribed = subscription.new
		subscribed.user_id = subscriber.id
		subscribed.item_template_id = item_template.id
		if Subscription.where(:item_template_id=> id).where(:user_id => follower.id) == []
			subscribed.save
		end
	end
	
	def create_subscription
		create_subscription(current_user)
	end
	
	def remove_subscription(subscriber)
		a = Subscription.where(:user_id=>followed.id).where(:item_template_id => id).first
		return a.destroy
	end
		
	def remove_subscription
		remove_subscription(current_user)
	end
	
    def fetch_location
	    @table = ENV['csb_locations']
	    return ::FT.execute "SELECT Location FROM #{@table} WHERE ID = #{item_id} AND Type = ItemTemplate.type "
    end

        #takes in a CSV of lat/lng
   	def insert_location(location)

	    @table = ENV['csb_locations']
	    return ::FT.execute "INSERT INTO #{@table} (ID, Type, Location, Category) VALUES (#{id}, '#{producible_type}', '#{location}', '#{cat_id}') "
	end

        #takes in a CSV of lat/lng and either quest, chall, or event
	def update_location(location)
	    @table = ENV['csb_locations']
	    @sanity_check = ::FT.execute "SELECT rowid FROM #{@table} WHERE ID = #{who.id} AND Type = #{ItemTemplate.type} "
	    if @sanity_check[0] == nil
	        return insert_location(location)
	    end
	    @rowid = @sanity_check[0][:rowid]

	    return ::FT.execute "UPDATE #{@table} SET Location = '#{ItemTemplate.location}' WHERE ROWID = '#{@rowid}' AND Type = #{ItemTemplate.type}"
	end

        #takes in a limit and typearray
	def grab_nearest(limit,typearray)
	    @table = ENV['csb_locations']
	    @lat = ItemTemplate.location.split(',')[0].to_f
	    @lng = ItemTemplate.location.split(',')[1].to_f
		resultHash = {}
		typearray.each do |type|
			resultHash.add(type => (::FT.execute "SELECT * FROM #{@table} WHERE Type = #{type} ORDER BY ST_DISTANCE(Location, LATLNG(#{@lat},#{@lng})) LIMIT #{limit}"))
			end
		return resultHash
	end
	
	def grab_area(points)
	    @table = ENV['csb_locations']
	    result = ::FT.execute "SELECT * FROM #{@table} WHERE ST_INTERSECTS(Location, #{points})) AND TYPE = #{x}"
	end
	
	def grab_circle(radius, target_loc,typearray)
	    @table = ENV['csb_locations']
	    @lat = target_loc.split[0].to_f
	    @lng = target_loc.split[1].to_f
		resulthash = {}
		typearray.each do |x|
			resulthash.add(x=>(::FT.execute "SELECT * FROM #{@table} WHERE ST_INTERSECTS(Location, CIRCLE(LATLNG(#{@lat}, #{@lng}), #{radius})) AND Type = '#{x}' "))
			end
		return resulthash
	end
	
	def sift_circle(radius, target_loc, set)
	    circles = grab_circle(distance, target_loc)
	    circles = retrieve_google_with_set(set, circles)
	    return circles
	end

	def retrieve_google_with_set(set, db_return)
	    rtn = []
	    db_return.each do |x|
	        rtn += [x[:item_id]]
			end
	    return set.followed(rtn)
	end

	def grab_rectangle(upper_right, lower_left,typearray)
	    @table = ENV['table']
	    @upper_right_x = upper_right.split[0].to_f
	    @upper_right_y = upper_right.split[1].to_f
	    @lower_left_x = lower_left.split[0].to_f
	    @lower_left_y = lower_left.split[1].to_f
		resulthash = {}
		typearray.each do |x|
			resulthash.add(x => ( ::FT.execute "SELECT * FROM #{@table} WHERE ST_INTERSECTS (Location, RECTANGLE(LATLNG(#{@upper_right_x}, #{@upper_right_y}), LATLNG(#{@lower_left_x}, #{@lower_left_y}))) AND Type = #{x}"))
			end
		return resulthash
	end

	def retrieve_entries(db_return)
	    rtn = []
	    db_return.each do |x|
	        rtn += [x[:item_id]]
	    end
	    return ItemTemplate.followed(rtn)
	end

	def combine_google_filter(db_return, set)
	    return set.where(:id => db_return)
	end

	def retrieve_google(db_return)
	    rtn = []
	    db_return.each do |x|
	        rtn += [x[:item_id]]
	    end
	    return ItemTemplate.followed(rtn)
	end

	#temporary most popular
	def most_popular(since_last, distance, target_location)
	    set = ItemTemplate.where("updated_at > '#{since_last}'").order("popularity DESC")
	    google_set = grab_circle(distance, target_location, 25)
	    google_fetch = retrieve_google(google_set)
	    return google_fetch.where("updated_at > '#{since_last}'").order("popularity DESC")
	end
	

	def most_popular(since_last, types)
		return ItemTemplate.find(:all, :conditions => ["updated_at > ? AND type IN (?)", since_last, types]).where()
    end

    
	 
	#def grab_circle(distance, target_loc)
   #  @events_table = ENV['csb_locations']
    # @loc_x = target_loc.split[0].to_f
     #@loc_y = target_loc.split[1].to_f
     #return ::FT.execute "SELECT * FROM #{@events_table} WHERE ST_INTERSECTS(Location, CIRCLE(LATLNG(#{@loc_x}, #{@loc_y}), #{distance}))"
	#end
   
   def grab_nearest(number)
	@item_table = ENV['csb_locations']
	@loc_x = location.split[0].to_f
	@loc_y = location.split[1].to_f
	return ::FT.execute "SELECT * FROM #{@item_table} ORDER BY ST_DISTANCE(Location, LATLNG(#{@loc_x},#{@loc_y})) LIMIT #{number}"
  end
  
  def sift_keyword_responses(key)
	sift = ResponseTemplate.where("response LIKE ? OR response LIKE ? OR response LIKE ?", "% " + key + " %", key, key + " %")
	set = []
	sift.each do |resp|
		set += [ItemTemplate.find(resp.item_template_id)]
		end
	return set
  end
  
  def sift_keyword_description(key)
	return ItemTemplate.where("description LIKE ? OR description LIKE ? OR description LIKE ?", "% " + key + " %", key, key + " %")
  end

  def sift_keyword_title(key)
	return ItemTemplate.where("title LIKE ? OR title LIKE ? OR title LIKE ?", "% " + key + " %", key, key + " %")
  end
  
  def sift_keyword(key)
	return sift_keyword_title(key) + sift_keyword_description(key)+sift_keyword_responses(key)
  end
  
  def sift_location(area)
    set = area.coordinates
    lineEquation = []
    set.each do |point|
      
    end
  end
  
end
