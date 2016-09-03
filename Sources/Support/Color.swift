// =============================================================================
// Color.swift 🖌
// Written by Andrew Thompson
// =============================================================================

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

	public subscript(index: Int) -> Color<DataType> {
		get {
			assert(index < length/4 && length % 4 == 0, "index out of range")
			let r = buffer[4 * index + 0]
			let g = buffer[4 * index + 1]
			let b = buffer[4 * index + 2]
			let a = buffer[4 * index + 3]
			return Color(r, g, b, a)
		}
		set(color) {
			assert(index < length/4 && length % 4 == 0, "index out of range")
			buffer[4 * index + 0] = color.red
			buffer[4 * index + 1] = color.green
			buffer[4 * index + 2] = color.blue
			buffer[4 * index + 3] = color.alpha
		}
	}
}

public struct ColorBufferGenerator<DataType> : IteratorProtocol { 
	public var nextIndex: () -> Color<DataType>?
	public init(_ method: @escaping () -> Color<DataType>?) {
		self.nextIndex = method
	}

	public func next() -> Color<DataType>? {
		return nextIndex()
	}
}

extension ColorBuffer : Sequence {

	func generate() -> ColorBufferGenerator<DataType> {
		var index = 0
		let length = self.length
		let next: () -> Color<DataType>? = {
			index += 1
			if (index * 4) <= length {
				return self[index]
			}
			return nil
		}
		return ColorBufferGenerator(next)
	}
}

extension ColorBuffer : Collection {
	public typealias Index = Int

	public func index(after i: Int) -> Int {
		return i + 1
	}

	public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
		let index = i + n + 1
		if index < self.length && index < limit {
			return index
		}
		return nil
	}

	public var startIndex: Int {
		return 0
	}
	public var endIndex: Int {
		return self.length
	}
}
