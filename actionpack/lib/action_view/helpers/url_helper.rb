module ActionView
  module Helpers
    # Provides a set of methods for making easy links and getting urls that depend on the controller and action. This means that
    # you can use the same format for links in the views that you do in the controller. The different methods are even named
    # synchronously, so link_to uses that same url as is generated by url_for, which again is the same url used for
    # redirection in redirect_to.
    module UrlHelper
      # Returns the URL for the set of +options+ provided. See the valid options in link:classes/ActionController/Base.html#M000021
      def url_for(options = {}, *parameters_for_method_reference)
        if Hash === options then options = { :only_path => true }.merge(options) end
        @controller.send(:url_for, options, *parameters_for_method_reference)
      end

      # Creates a link tag of the given +name+ using an URL created by the set of +options+. See the valid options in
      # link:classes/ActionController/Base.html#M000021. It's also possible to pass a string instead of an options hash to
      # get a link tag that just points without consideration. The html_options have a special feature for creating javascript
      # confirm alerts where if you pass :confirm => 'Are you sure?', the link will be guarded with a JS popup asking that question.
      # If the user accepts, the link is processed, otherwise not.
      def link_to(name, options = {}, html_options = {}, *parameters_for_method_reference)
        convert_confirm_option_to_javascript!(html_options) unless html_options.nil?
        if options.is_a?(String)
          content_tag "a", name, (html_options || {}).merge({ "href" => options })
        else
          content_tag("a", name, (html_options || {}).merge({ "href" => url_for(options, *parameters_for_method_reference) }))
        end
      end

      # Creates a link tag to the image residing at the +src+ using an URL created by the set of +options+. See the valid options in
      # link:classes/ActionController/Base.html#M000021. It's also possible to pass a string instead of an options hash to
      # get a link tag that just points without consideration. The <tt>html_options</tt> works jointly for the image and ahref tag by
      # letting the following special values enter the options on the image and the rest goes to the ahref:
      #
      # ::alt: If no alt text is given, the file name part of the +src+ is used (capitalized and without the extension)
      # ::size: Supplied as "XxY", so "30x45" becomes width="30" and height="45"
      # ::align: Sets the alignment, no special features
      #
      # The +src+ can be supplied as a... 
      # * full path, like "/my_images/image.gif"
      # * file name, like "rss.gif", that gets expanded to "/images/rss.gif"
      # * file name without extension, like "logo", that gets expanded to "/images/logo.png"
      def link_to_image(src, options = {}, html_options = {}, *parameters_for_method_reference)
        image_options = { "src" => src.include?("/") ? src : "/images/#{src}" }
        image_options["src"] = image_options["src"] + ".png" unless image_options["src"].include?(".")
        
        if html_options["alt"]
          image_options["alt"] = html_options["alt"]
          html_options.delete "alt"
        else
          image_options["alt"] = src.split("/").last.split(".").first.capitalize
        end

        if html_options["size"]
          image_options["width"], image_options["height"] = html_options["size"].split("x")
          html_options.delete "size"
        end
        
        if html_options["align"]
          image_options["align"] = html_options["align"]
          html_options.delete "align"
        end

        link_to(tag("img", image_options), options, html_options, *parameters_for_method_reference)
      end

      # Creates a link tag of the given +name+ using an URL created by the set of +options+, unless the current 
      # controller, action, and id are the same as the link's, in which case only the name is returned (or the
      # given block is yielded, if one exists). This is useful for creating link bars where you don't want to link 
      # to the page currently being viewed.
      def link_to_unless_current(name, options = {}, html_options = {}, *parameters_for_method_reference)
        assume_current_url_options!(options)

        if destination_equal_to_current(options)
          block_given? ?
            yield(name, options, html_options, *parameters_for_method_reference) :
            html_escape(name)
        else
          link_to name, options, html_options, *parameters_for_method_reference
        end
      end

      # Creates a link tag for starting an email to the specified <tt>email_address</tt>, which is also used as the name of the
      # link unless +name+ is specified. Additional HTML options, such as class or id, can be passed in the <tt>html_options</tt> hash.
      def mail_to(email_address, name = nil, html_options = {})
        content_tag "a", name || email_address, html_options.merge({ "href" => "mailto:#{email_address}" })
      end

      private
        def destination_equal_to_current(options)
          params_without_location = @params.reject { |key, value| %w( controller action id ).include?(key) }

          options[:action] == @params['action'] &&
            options[:id] == @params['id'] &&
            options[:controller] == @params['controller'] &&
            (options.has_key?(:params) ? params_without_location == options[:params] : true) 
        end

        def assume_current_url_options!(options)
          if options[:controller].nil?
            options[:controller] = @params['controller']
            if options[:action].nil?
              options[:action] = @params['action']
              if options[:id].nil? then options[:id] ||= @params['id'] end
            end
          end
        end
        
        def convert_confirm_option_to_javascript!(html_options)
          if html_options.include?(:confirm)
            html_options["onclick"] = "return confirm('#{html_options[:confirm]}');"
            html_options.delete(:confirm)
          end
        end
    end
  end
end