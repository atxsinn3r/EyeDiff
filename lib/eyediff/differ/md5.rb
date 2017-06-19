require 'digest'

module EyeDiff::Differ
  class MD5
    def initialize(image1_md5, image2_md5)
      @images =
        [
          Digest::MD5.hexdigest(image1_md5),
          image2_md5
        ]
    end

    def same?
      @images.first == @images.last
    end
  end
end
