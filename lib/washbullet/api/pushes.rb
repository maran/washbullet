module Washbullet
  module API
    module Pushes
      def push_note(target, title, body)
        push :note, target, title: title, body: body
      end

      def push_link(target, title, url, body)
        push :link, target, title: title, url: url, body: body
      end

      def push_address(target, name, address)
        push :address, target, name: name, address: address
      end

      def push_list(target, title, items)
        push :list, target, title: title, items: items
      end

      def push_file(target, file_name, file_path, body)
        upload_file(file_name, file_path) do |data|
          payload = {
            file_name: data['file_name'],
            file_type: data['file_type'],
            file_url:  data['file_url'],
            body:      body
          }

          push :file, target, payload
        end
      end

      def pushes(modified_after = nil, cursor = nil)
        params = {modified_after: modified_after, cursor: cursor}

        params = params.values.all?(&:nil?) ? {} : params

        get 'v2/pushes', params
      end

      def delete_push(push_iden)
        delete "/v2/pushes/#{push_iden}"
      end

      private

      def upload_file(file_name, file_path, &block)
        mime_type = MIME::Types.type_for(file_path).first.to_s

        data = upload_request(file_name, mime_type)

        upload_url = data.body['upload_url']
        payload    = data.body['data']

        io   = Faraday::UploadIO.new(file_path, mime_type)

        post upload_url, payload.merge(file: io)

        yield data.body
      end

      def upload_request(file_name, mime_type)
        get '/v2/upload-request', file_name: file_name, file_type: mime_type
      end

      def push(type, target, payload)
        if target.is_a?(Hash) && [:device_iden, :email, :channel_tag, :client_iden].include?(target.keys.first)
          post '/v2/pushes', payload.merge(type: type).merge(target)
        else
          post '/v2/pushes', payload.merge(device_iden: target, type: type)
        end
      end
    end
  end
end
