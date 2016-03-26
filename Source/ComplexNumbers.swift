import Foundation

public struct Complex : Equatable, CustomStringConvertible, Hashable {
    public static var accuraccy: Double = 0.00001
    public var real: Double
    public var imaginary: Double
    
    public init() {
        self.init(0, 0)
    }
    public init(_ real: Double, _ imaginary: Double) {
        self.real = real
        self.imaginary = imaginary
    }
    public var description: String {
        let r = String(format: "%f", real)
        let i = String(format: "%f", abs(imaginary))
        var result = ""
        switch (real, imaginary) {
        case _ where imaginary == 0:
            result = "\(r)"
        case _ where real == 0:
            result = "\(i)𝒊"
        case _ where imaginary < 0:
            result = "\(r) - \(i)𝒊"
        default:
            result = "\(r) + \(i)𝒊"
        }
        return result
    }
    
    public var arg: Double {
       return atan2(imaginary, real)
    }
    
    public var hashValue: Int {
        return Int(real) ^ Int(imaginary)
    }
}

public func ==(lhs: Complex, rhs: Complex) -> Bool {
    return lhs.real == rhs.real && lhs.imaginary == rhs.imaginary
}
public func +(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real + rhs.real, lhs.imaginary + rhs.imaginary)
}
public func -(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real - rhs.real, lhs.imaginary - rhs.imaginary)
}
public prefix func -(c1: Complex) -> Complex {
    return Complex(-c1.real, -c1.imaginary)
}
public func *(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real * rhs.real - lhs.imaginary * rhs.imaginary, lhs.real * rhs.imaginary + rhs.real * lhs.imaginary)
}
public func /(lhs: Complex, rhs: Complex) -> Complex {
    let denominator = (rhs.real * rhs.real + rhs.imaginary * rhs.imaginary)
    return Complex((lhs.real * rhs.real + lhs.imaginary * rhs.imaginary) / denominator,
                    (lhs.imaginary * rhs.real - lhs.real * rhs.imaginary) / denominator)
}

// -----------------------------------------------------------------------------
//                          Assignment Operators
// -----------------------------------------------------------------------------

public func +=(inout lhs: Complex, rhs: Complex) {
    lhs = lhs + rhs
}
public func -=(inout lhs: Complex, rhs: Complex) {
    lhs = lhs - rhs
}
public func *=(inout lhs: Complex, rhs: Complex) {
    lhs = lhs * rhs
}
public func /=(inout lhs: Complex, rhs: Complex) {
    lhs = lhs / rhs
}

// -----------------------------------------------------------------------------
//                    Complex Numebrs and other Numbers
// -----------------------------------------------------------------------------

public func +(lhs: Double, rhs: Complex) -> Complex { // Real plus imaginary
    return Complex(lhs + rhs.real, rhs.imaginary)
}
public func -(lhs: Double, rhs: Complex) -> Complex { // Real minus imaginary
    return Complex(lhs - rhs.real, -rhs.imaginary)
}
public func *(lhs: Double, rhs: Complex) -> Complex { // Real times imaginary
    return Complex(lhs * rhs.real, lhs * rhs.imaginary)
}
public func /(lhs: Double, rhs: Complex) -> Complex { // Real divide imaginary
    return Complex(lhs / rhs.real, lhs / rhs.imaginary)
}

public func /(lhs: Complex, rhs: Double) -> Complex { // Imaginary divide real
    return Complex(lhs.real / rhs, lhs.imaginary / rhs)
}
public func -(lhs: Complex, rhs: Double) -> Complex { // Imaginary minus real
    return Complex(lhs.real - rhs, lhs.imaginary)
}
public func +(lhs: Complex, rhs: Double) -> Complex { // Imaginary plus real
    return Complex(lhs.real + rhs, lhs.imaginary)
}
public func *(lhs: Complex, rhs: Double) -> Complex { // Imaginary times real
    return Complex(lhs.real * rhs, lhs.imaginary * rhs)
}

// -----------------------------------------------------------------------------
//                              Functions
// -----------------------------------------------------------------------------

public func abs(n: Complex) -> Double {
    return sqrt(n.real * n.real + n.imaginary * n.imaginary)
}
public func modulus(n: Complex) -> Double {
    return abs(n)
}

public func **(lhs: Double, rhs: Double) -> Double {
    return pow(lhs, rhs)
}

public func pow(base: Complex, _ n: Double) -> Complex {
    let r = modulus(base) ** n
    let arg = base.arg
    let real = r * cos(n * arg)
    let imaginary = r * sin(n * arg)
    return Complex(real, imaginary)
}

infix operator ** { associativity left precedence 160 }
public func **(base: Complex, n: Double) -> Complex {
    return pow(base, n)
}
public func **(base: Complex, n: Int) -> Complex {
    return pow(base, Double(n))
}

public func factorial(n: Int) -> Int {
    if n == 0 {
        return 1
    }
    var sum = 1
    for it in 1...n {
        sum *= it
    }
    return sum
}

public func e(x: Double, accuracy: Int = 5) -> Double {
    var sum = 0.0
    for n in 0...accuracy {
        sum += x ** Double(n) / Double(factorial(n))
    }
    return sum
}
public func e(x: Complex, accuracy: Int = 5) -> Complex {
    let r = e(x.real, accuracy: accuracy)
    return Complex(cos(x.imaginary), sin(x.imaginary)) * r
}
public func sin(theta: Complex) -> Complex {
    let p1 = e(Complex(0, 1) * theta)
    let p2 = e(Complex(0, 1) * -theta)
    return (p1 - p2) / (2 * Complex(0, 1))
}
public func cos(theta: Complex) -> Complex {
    let p1 = e(Complex(0, 1) * theta)
    let p2 = e(Complex(0, 1) * -theta)
    return (p1 + p2) / 2
}


public struct ComplexRect : Equatable, CustomStringConvertible {
    public var topLeft: Complex = Complex() {
        didSet {
            let c1 = topLeft
            let c2 = bottomRight
            let tlr = min(c1.real, c2.real)
            let tli = max(c1.imaginary, c2.imaginary)
            let brr = max(c1.real, c2.real)
            let bri = min(c1.imaginary, c2.imaginary)
//        Avoid runtime recursion
//            topLeft     = Complex(tlr, tli)
            bottomRight = Complex(brr, bri)
            bottomLeft = Complex(tlr, bri)
            topRight = Complex(brr, tli)
        }
    }
    public var bottomRight: Complex = Complex() {
        didSet {
            let c1 = topLeft
            let c2 = bottomRight
            let tlr = min(c1.real, c2.real)
            let tli = max(c1.imaginary, c2.imaginary)
            let brr = max(c1.real, c2.real)
            let bri = min(c1.imaginary, c2.imaginary)
            topLeft     = Complex(tlr, tli)
//        Avoid runtimec recursion
//            bottomRight = Complex(brr, bri)
            bottomLeft = Complex(tlr, bri)
            topRight = Complex(brr, tli)
        }
    }
    private(set) var bottomLeft: Complex = Complex()
    private(set) var topRight: Complex = Complex()
    
    public init(_ c1: Complex, _ c2: Complex) {
        let tlr = min(c1.real, c2.real)
        let tli = max(c1.imaginary, c2.imaginary)
        let brr = max(c1.real, c2.real)
        let bri = min(c1.imaginary, c2.imaginary)
        topLeft     = Complex(tlr, tli)
        bottomRight = Complex(brr, bri)
        bottomLeft = Complex(tlr, bri)
        topRight = Complex(brr, tli)
    }
    public var description: String {
        return "tl: \(topLeft), br: \(bottomRight), bl: \(bottomLeft), tr: \(topRight)"
    }
}
public func ==(lhs: ComplexRect, rhs: ComplexRect) -> Bool {
    return (lhs.topLeft == rhs.topLeft) && (lhs.bottomRight == rhs.bottomRight)
}