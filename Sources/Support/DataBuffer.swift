// =============================================================================
// DataBuffer 🐃
// 
// Written by Andrew Thompson
// =============================================================================

class DataBuffer<Type> {
    var data: UnsafeMutablePointer<Type>
    var count: Int

    init(count: Int, initialValue: Type) {
        self.count = count
        data = UnsafeMutablePointer<Type>.allocate(capacity: count)
        data.initialize(to: initialValue, count: count)
    }
    deinit {
        data.deinitialize(count: count)
        data.deallocate(capacity: count)
    }

    var range: Range<Int> {
        return 0..<count
    }

    subscript(index: Int) -> Type {
        get {
            assert(range.contains(index), "out of bounds access")
            return data[index]
        }
        set {
            assert(range.contains(index), "out of bounds access")
            data[index] = newValue
        }
    }
}
