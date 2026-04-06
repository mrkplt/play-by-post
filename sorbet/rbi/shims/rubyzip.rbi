# typed: true

module Zip
  class OutputStream
    sig { params(file_name: String, encrypter: T.untyped, block: T.proc.params(zip: Zip::OutputStream).void).returns(StringIO) }
    def self.write_buffer(file_name = "", encrypter = NullEncrypter.new, &block); end

    sig { params(name: String, compression_method: Integer, size: T.nilable(Integer)).void }
    def put_next_entry(name, compression_method = Entry::DEFLATED, size = nil); end

    sig { params(data: String).returns(Integer) }
    def write(data); end
  end

  class InputStream
    sig { params(filename_or_io: T.any(String, IO, StringIO), offset: Integer, block: T.proc.params(zip: Zip::InputStream).void).void }
    def self.open(filename_or_io, offset = 0, &block); end

    sig { returns(T.nilable(Entry)) }
    def get_next_entry; end

    sig { params(length: T.nilable(Integer)).returns(String) }
    def read(length = nil); end
  end

  class Entry
    DEFLATED = T.let(8, Integer)
    STORED = T.let(0, Integer)

    sig { returns(String) }
    def name; end
  end

  class NullEncrypter; end
end
