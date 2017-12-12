Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'search#search'
  get '/:id/search', to: 'search#search'
end
