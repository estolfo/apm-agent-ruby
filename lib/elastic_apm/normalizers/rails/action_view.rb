# frozen_string_literal: true

module ElasticAPM
  module Normalizers
    module ActionView
      # @api private
      class RenderNormalizer < Normalizer
        private

        def normalize_render(payload, type, subtype, action)
          [path_for(payload[:identifier]), type, subtype, action, nil]
        end

        def path_for(path)
          return 'Unknown template' unless path
          return path unless path.start_with?('/')

          view_path(path) || gem_path(path) || 'Absolute path'
        end

        def view_path(path)
          root = @config.__view_paths.find { |vp| path.start_with?(vp) }
          return unless root

          strip_root(root, path)
        end

        def gem_path(path)
          root = Gem.path.find { |gp| path.start_with? gp }
          return unless root

          format '$GEM_PATH/%s', strip_root(root, path)
        end

        def strip_root(root, path)
          start = root.length + 1
          path[start, path.length]
        end
      end

      # @api private
      class RenderTemplateNormalizer < RenderNormalizer
        register 'render_template.action_view'
        TYPE = 'template'
        SUBTYPE = 'view'

        def normalize(_transaction, _name, payload)
          normalize_render(payload, TYPE, SUBTYPE, nil)
        end
      end

      # @api private
      class RenderPartialNormalizer < RenderNormalizer
        register 'render_partial.action_view'
        TYPE = 'template'
        SUBTYPE = 'view'
        ACTION = 'partial'

        def normalize(_transaction, _name, payload)
          normalize_render(payload, TYPE, SUBTYPE, ACTION)
        end
      end

      # @api private
      class RenderCollectionNormalizer < RenderNormalizer
        register 'render_collection.action_view'
        TYPE = 'template'
        SUBTYPE = 'view'
        ACTION = 'collection'

        def normalize(_transaction, _name, payload)
          normalize_render(payload, TYPE, SUBTYPE, ACTION)
        end
      end
    end
  end
end
