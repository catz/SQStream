require "goliath"
require 'yajl/json_gem'

class Stream < Goliath::API
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format
  use Goliath::Rack::Params             # parse & merge query and body parameters
  use Goliath::Rack::Heartbeat          # respond to /status with 200, OK (monitoring, etc)

  use Goliath::Rack::Validation::RequestMethod, %w(GET POST)           # allow GET and POST requests only
  %w[sig social_id].each{|param|
  	use Goliath::Rack::Validation::RequiredParam, {key: param, message: "#{param} is missing", type: "Param"}
  } 

	def on_headers(env, headers)
		env.logger.info "headers: " + headers.inspect
		env['async-headers'] = headers

		# MAKE SOME HEADER CHECKS
	end

	def on_body(env, data)
		env.logger.info "data: " + data
		(env['async-body'] ||= '') << data
	end

	def on_close(env)
		env.logger.info 'closing connection'
	end

	def events_post(params, data)
		track_event(rand(8**32).to_s(36), params, data)
	end

	def events_get(params, data)
		data = redis.lrange(prepare_key(params), 0, -1)
	end
	
	def response(env)
		data = env['async-body']
		resp = case(env[Goliath::Request::REQUEST_METHOD]) 
		when 'GET' then events_get(params, data)
		when 'POST' then events_post(params, data)
		else env.logger.error "UNKNOWN METHOD #{env[Goliath::Request::REQUEST_METHOD]}" 
		end
		
		[200, {}, resp]
	end
	
	private

	def prepare_key(params)
		"#{params[:social_id]}:#{params[:app_id]}:events:#{params[:user_id]}"
	end

  def track_event(event_id, params, event_data)
    redis.lpush prepare_key(params), event_data
  end
end