public struct Color<Type> {
	public var red: Type
	public var green: Type
	public var blue: Type
	public var alpha: Type

	public init(_ red: Type, _ green: Type, _ blue: Type, _ alpha: Type) {
		self.red = red
		self.green = green
		self.blue = blue
		self.alpha = alpha
	}
}

public struct ColorBuffer<DataType> {
	public var buffer: UnsafeMutablePointer<DataType>
	public var length: Int

	/// Pass `true` to `ownsBuffer` to have the object destroy the buffer once it's lifetime is up.
	public init(buffer: UnsafeMutablePointer<DataType>, length: Int) {
		assert(length % 4 == 0, "buffer length must be a multiple of 4")
		self.buffer = buffer
		self.length = length
	}

	public subscript (index: Int) -> Color<DataType> {
		get {
			assert(index < length/4 , "index out of range")
			let r = buffer[index + 0]
			let g = buffer[index + 1]
			let b = buffer[index + 2]
			let a = buffer[index + 3]
			return Color(r, g, b, a)
		}
		set(color) {
			assert(index < length/4, "index out of range")
			buffer[index + 0] = color.red
			buffer[index + 1] = color.green
			buffer[index + 2] = color.blue
			buffer[index + 3] = color.alpha
		}
	}
}
