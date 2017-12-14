include CharacterizationHelper

class CreateDerivativesJob < ActiveJob::Base
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] repository_file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform( file_set, repository_file_id, filepath = nil, delete_input_file = true )
    CharacterizationHelper.create_derivatives( file_set, repository_file_id, filepath, delete_input_file: delete_input_file )
  rescue Exception => e
    Rails.logger.error "CreateDerivativesJob.perform(#{file_set},#{repository_file_id},#{filepath}) #{e.class}: #{e.message}"
  end

end
