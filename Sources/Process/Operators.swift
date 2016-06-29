// =============================================================================
// Operators ⏈
//
//  Contains operators which make life easier when wanting to experiment quickly
//  with different combinations of computers and colorizers.
//
// Written by Andrew Thompson
// =============================================================================

// Hmm, what would be some ideal usage?
//
// Chaining a computer, coloriser, then a controller all in one line?
// Yeah
// Taking a two computers and feeding that into another computer, which then 
// allows us to colorize it.
// 
// Sample chaining patters:
//    Computer -> Colorizer -> Output
//    Computer -> Computer -> Colorizer -> Computer -> Output -> Colorizer -> Output
//

// chain (computer, computer)
// chain (computer, colorizer)
// chain (colorizer, computer)
// chain (colorizer, output)
// chain (output, colorizer)

// Then we need a rendering command?
// Yeah.
// 
// We need a controller object.
// The chain functions return an array of objects.
// The renderer iterates over the array and then performs the requested actions.
// Depending on the type of function, we could have it define custom behaviour.
// 
// E.g.
//
//      MandelbrotSet() >> JuliaSet() > ModulusColorizer() > FileWriter() ~
//
// So the `>` is the chain operator, and the `>>` is a compound chain (whateve that
// means. Finally, the `~` operator could mean that we want to start the rendering
// process now.
//
// Some other operators could be @, for file writer (or maybe a path? 😬), # for
// renderer, ∆ (option-j) for differentiation? and ∫ (option-b) for integration?
// ≈ (option-x) for double chain. There is also ≤ (option-,) and ≥ (option-.).
// 
//
// It would be nice to also have closures in the midst. For example, have dedicated
// protocol for coloring probably isn't the best choice when a simple function could
// have surficed.
