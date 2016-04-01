import CLibTIFF

var tif = TIFFOpen("/Users/mrwerdo/Developer/Fractals/redesigned-palm-tree-fractals/Fractal.tiff", "w")
if tif != nil {
	var width: UInt32 = 100
	var height: UInt32 = 100
	let size = Int(width * height * 4)

	TIFFSetField_uint32(tif, UInt32(TIFFTAG_IMAGEWIDTH), width)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_IMAGELENGTH), height)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_BITSPERSAMPLE), 8)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_SAMPLESPERPIXEL), 4)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_ROWSPERSTRIP), 1)

	var extraChannels: [UInt16] = [UInt16(EXTRASAMPLE_ASSOCALPHA)]
	TIFFSetField_ExtraSample(tif, 1, &extraChannels)
	
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_PHOTOMETRIC), UInt32(PHOTOMETRIC_RGB))
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_PLANARCONFIG), UInt32(PLANARCONFIG_CONTIG))
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_ORIENTATION), UInt32(ORIENTATION_TOPLEFT))

	var buffer = [[UInt8]](count: Int(height), repeatedValue: [UInt8](count: Int(width * 4), repeatedValue: 0))

	for y in 0..<Int(height) {
		for x in 0.stride(to: Int(width * 4), by: 4) {
			buffer[y][x] = UInt8(x % 255)
			buffer[y][x+2] = UInt8((Int(width * 4) - x) % 255)
			buffer[y][x+1] = 0
			buffer[y][x+3] = 255 // alpha
		}
	}

	for row in 0..<Int(height) {
		var k: [UInt8] = buffer[row]
		if TIFFWriteScanline(tif, &k, UInt32(row), 0) < 0 {
			print("Error!")
		}
	}

	print("The size is: \(width)x\(height)")
}
TIFFClose(tif)
