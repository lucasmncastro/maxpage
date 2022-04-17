Maxdog::Engine.routes.draw do
  get 'metrics/index', as: :metrics_index
  root 'metrics#index'
end
