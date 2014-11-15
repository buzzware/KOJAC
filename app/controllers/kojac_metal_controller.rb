class KojacMetalController < ActionController::Metal
  def index
    self.response_body = "Hello World!"
  end
end
