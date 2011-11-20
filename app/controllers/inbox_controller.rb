class InboxController < ApplicationController
  def respond
    
      @message = current_user.message_copys[params[:message_id].to_i].message

  end
  def index
    @messages = current_user.message_copys
  end
  
  def show
    @success = "It a me, mario!"
    @messages = current_user.message_copys
  end
  
  def new
   
  end
  
  def create
    id = User.find_by_login(params[:sendTo]).id
    body = params[:body]
    subject = params[:subject]
    message = Message.create(:user_id => current_user.id, :body => body, :subject => subject)
    MessageCopy.create(:message_id => message.id, :user_id => id)
    @success = false 
    if message.id != nil
      @success = true
    end
    if @success == false
      redirect_to messages_new_path
    else
      redirect_to messages_inbox_path
    end
    
  end
  
end
