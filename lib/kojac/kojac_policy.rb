#require "pundit/version"
require "pundit/policy_finder"
#require "active_support/concern"
#require "active_support/core_ext/string/inflections"
#require "active_support/core_ext/object/blank"

module Kojac
  #class NotAuthorizedError < StandardError; end
  #class NotDefinedError < StandardError; end

  extend ActiveSupport::Concern

  class << self
    def policy_scope(user, scope, op)
      policy = Pundit::PolicyFinder.new(scope).scope
      policy.new(user, scope, op).resolve if policy
    end

    def policy_scope!(user, scope, op)
	    Pundit::PolicyFinder.new(scope).scope!.new(user, scope, op).resolve
    end

    def policy(user, record, op)
      scope = Pundit::PolicyFinder.new(record).policy
      scope.new(user, record, op) if scope
    end

    def policy!(user, record, op)
	    Pundit::PolicyFinder.new(record).policy!.new(user, record, op)
    end
  end

  included do
    if respond_to?(:helper_method)
      helper_method :policy_scope
      helper_method :policy
    end
    if respond_to?(:hide_action)
      hide_action :authorize
      hide_action :verify_authorized
      hide_action :verify_policy_scoped
    end
  end

  def verify_authorized
    raise NotAuthorizedError unless @_policy_authorized
  end

  def verify_policy_scoped
    raise NotAuthorizedError unless @_policy_scoped
  end

  def authorize(record, query=nil)
    query ||= params[:action].to_s + "?"
    @_policy_authorized = true
    unless policy(record).public_send(query)
      raise NotAuthorizedError, "not allowed to #{query} this #{record}"
    end
    true
  end

  def policy_scope(scope)
    @_policy_scoped = true
    Pundit::Pundit.policy_scope!(current_user, scope, op)
  end

  def policy(record)
	  Pundit::Pundit.policy!(current_user, record, op)
  end
end
