import DemucsMLX
import Foundation
import Testing

@Test("Registry exposes htdemucs")
func registryContainsDefaultModel() {
    #expect(listAvailableDemucsModels().contains("htdemucs"))
}

@Test("Parameter validation rejects invalid overlap")
func invalidOverlapRejected() {
    #expect(throws: DemucsError.self) {
        _ = try DemucsSeparator(
            modelName: "htdemucs",
            parameters: DemucsSeparationParameters(overlap: 1.1),
            modelDirectory: FileManager.default.temporaryDirectory
        )
    }
}

@Test("A model missing from the given directory is an error")
func missingModelRejected() throws {
    let empty = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: empty) }

    #expect(throws: DemucsError.self) {
        _ = try DemucsSeparator(modelName: "htdemucs", modelDirectory: empty)
    }
}
