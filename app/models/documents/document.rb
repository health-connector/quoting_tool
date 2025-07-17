# frozen_string_literal: true

module Documents
  # Document model representing various document types in the system
  # This model follows the Dublin Core Metadata Element Set for document metadata
  # and provides a standardized way to store document information
  class Document
    include Mongoid::Document
    include Mongoid::Timestamps

    # Valid access rights for documents
    ACCESS_RIGHTS = %w[public pii_restricted].freeze

    # Documents can be embedded in any documentable entity
    embedded_in :documentable, polymorphic: true

    # Dublin Core metadata elements
    # The name given to the resource
    field :title, type: String, default: 'untitled'

    # Entity responsible for making the resource - person, organization or service
    field :creator, type: String, default: 'mhc'

    # Controlled vocabulary w/classification codes. Mapped to ConsumerRole::VLP_DOCUMENT_KINDS
    field :subject, type: String

    # May include but is not limited to: an abstract, a table of contents, a graphical representation,
    # or a free-text account of the resource
    field :description, type: String

    # Entity responsible for making the resource available - person, organization or service
    field :publisher, type: String, default: 'mhc'

    # Entity responsible for making contributions to the resource - person, organization or service
    field :contributor, type: String

    # A point or period of time associated with an event in the lifecycle of the resource.
    field :date, type: Date

    # Conforms to DCMI Type Vocabulary - http://dublincore.org/documents/2000/07/11/dcmi-type-vocabulary/
    field :type, type: String, default: 'text'

    # Conforms to IANA mime types - http://www.iana.org/assignments/media-types/media-types.xhtml
    field :format, type: String, default: 'application/octet-stream'

    # An unambiguous reference to the resource - Conforms to URI
    field :identifier, type: String

    # A related resource from which the described resource is derived
    field :source, type: String, default: 'enroll_system'

    # Conforms to ISO 639
    field :language, type: String, default: 'en'

    # A related resource - a string conforming to a formal identification system
    field :relation, type: String

    # Spatial (e.g. "District of Columbia") or temporal (e.g. "Open Enrollment 2016") topic of the resource
    field :coverage, type: String

    # Conforms to ACCESS_RIGHTS above
    field :rights, type: String

    # Additional metadata tags for the document
    field :tags, type: Array, default: []

    # Size of the document in bytes
    field :size, type: String

    # Validation requirements for document metadata
    validates :title, :creator, :publisher, :type, :format, :source, :language, presence: true

    validates :rights,
              allow_blank: true,
              inclusion: { in: ACCESS_RIGHTS, message: '%<value>s is not a valid access right' }
  end
end
