Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'sessions#index'
  get 'home', to: 'sessions#index'
  post 'connect', to: 'sessions#create'
  get 'disconnect', to: 'sessions#destroy'
  get 'dashboard', to: 'dashboard#index'
  get 'tasks/:id/:status', to: 'tasks#update_task'
  get 'poll_tasks', to: 'tasks#poll_tasks'
end
