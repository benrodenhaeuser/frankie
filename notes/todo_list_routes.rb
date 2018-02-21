# controllers for todo list app

get "/" do
  redirect "/lists"
end

# show all lists
get "/lists" do
  erb(:lists, layout: :layout)
end

# show new list form
get "/lists/new" do
  erb(:new_list, layout: :layout)
end

# show list
get "/lists/:id" do
  @list_id = params[:id].to_s
  @list = load_list(params[:id])
  erb(:list, layout: :layout)
end

# show edit form for existing todo list
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = load_list(params[:id])
  erb(:edit_list, layout: :layout)
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  error = list_error_message(list_name)

  if error
    session[:error] = error
    erb(:new_list, layout: :layout)
  else
    @list_id = next_list_id
    @lists << { name: list_name, todos: [], id: @list_id }
    session[:success] = "List has been succesfully created!"
    redirect "/lists/#{@list_id}"
  end
end

# update existing todo list
post "/lists/:id" do
  @id = params[:id].to_i
  @list = load_list(params[:id])
  list_name = params[:list_name].strip
  error = list_error_message(list_name)

  if error
    session[:error] = error
    erb(:edit_list, layout: :layout)
  else
    @list[:name] = list_name
    session[:success] = "List has been succesfully renamed!"
    redirect "/lists/#{@id}"
  end
end

# create new todo
post "/lists/:id/todos" do
  @id = params[:id].to_i
  @list = load_list(params[:id])
  todo_name = params[:todo].strip
  error = todo_error_message(todo_name)

  if error
    session[:error] = "Todos have to contain at least one character."
    erb(:list, layout: :layout)
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << { id: id, name: todo_name, completed: false }
    session[:success] = "Todo has been succesfully added!"
    redirect "/lists/#{@id}"
  end
end

# delete todo list
post "/lists/:id/delete" do
  @id = params[:id].to_i
  @lists.delete(load_list(params[:id]))
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# delete a todo
post "/lists/:id/todos/:todo_id/delete" do
  @list_id = params[:id].to_i
  todo_id = params[:todo_id].to_i
  todo = find_todo_by_id(load_list(params[:id]), todo_id)
  @lists[@list_id][:todos].delete(todo)
  if env["HTTP_X_REQUESTED_WITH"] == 'XMLHttpRequest'
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# mark all todos as completed
post "/lists/:id/todos/complete_all" do
  @list_id = params[:id].to_i
  @list = @lists[@list_id]
  todos = @list[:todos]

  todos.each { |todo| todo[:completed] = true }
  session[:success] = "The todos have been marked completed."
  redirect "/lists/#{@list_id}"
end

# update complete status of a todo
post "/lists/:id/todos/:todo_id" do
  @list_id = params[:id].to_i
  @list = @lists[@list_id]
  todo_id = params[:todo_id].to_i
  new_todo_status = (params[:completed] == 'true')
  todo = find_todo_by_id(load_list(params[:id]), todo_id)
  todo[:completed] = new_todo_status
  session[:success] = "The todo has been updated."

  redirect "/lists/#{@list_id}"
end
