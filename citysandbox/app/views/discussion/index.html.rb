<h1>Discussion#index</h1>
<p>Summary page!/</p>


<table>
  <tr>
    <th></th>
    <th></th>
    <th></th>
  </tr>
  <tr>
	<td>
		Do I exist?
	<%=h @silly %>
	</td>
  </tr>
	

<% @collection.each_with_index do |cityEvent, index| %>
  <tr>
	<td>
	  <%=h cityEvent[0].title %>
	</td>


	<td>
	  <b>Created at:</b>
	  <%=h cityEvent[0].created_at %>
	</td>
    <% cityEvent[1].each do |x| %>
	<td>
	  <b>Created by:</b>
	<%=h x.user.login %>
	 <b> who said: </b>
	<%=h x.response%>

	
	<tr>
		 <td>
		<%h x.response %>
		</td>
	</tr>
	
	</td>
	<% end %>
  </tr>
<% end %>
</table>