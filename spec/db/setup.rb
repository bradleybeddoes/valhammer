require 'active_record'
require 'logger'

FileUtils.rm_f 'spec/db/test.sqlite3'

ActiveRecord::Base.logger = Logger.new($stderr)
ActiveRecord::Base.extend Valhammer::Validations

ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
                                        database: 'spec/db/test.sqlite3')

require_relative 'schema.rb'
