import Foundation
import MLX

/// Shared utilities for resolving model directories, loading configs, and loading weights.
enum ModelLoader {
    /// Resolve the directory containing model files (safetensors + config JSON).
    /// Only `directory/<modelName>/` and `directory` itself are searched.
    static func resolveModelDirectory(modelName: String, in directory: URL) throws -> URL {
        let candidates = [directory.appendingPathComponent(modelName, isDirectory: true), directory]
        if let found = candidates.first(where: { hasRequiredModelFiles(in: $0, modelName: modelName) }) {
            return found
        }
        throw DemucsError.unsupportedModelBackend(
            "Could not find '\(modelName).safetensors' and '\(modelName)_config.json' in "
            + candidates.map(\.path).joined(separator: " or ") + "."
        )
    }

    /// Load and parse the model config JSON.
    static func loadConfig(from directory: URL, modelName: String) throws -> [String: Any] {
        let configURL = directory.appendingPathComponent("\(modelName)_config.json")
        let data = try Data(contentsOf: configURL)
        guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DemucsError.unsupportedModelBackend("Invalid model config JSON")
        }
        return raw
    }

    /// Load all weight arrays from safetensors file.
    static func loadWeights(from directory: URL, modelName: String) throws -> [String: MLXArray] {
        let weightsURL = directory.appendingPathComponent("\(modelName).safetensors")
        return try MLX.loadArrays(url: weightsURL)
    }

    /// Check if required model files exist in a directory.
    static func hasRequiredModelFiles(
        in directory: URL,
        modelName: String,
        fileManager: FileManager = .default
    ) -> Bool {
        let weights = directory.appendingPathComponent("\(modelName).safetensors")
        let config = directory.appendingPathComponent("\(modelName)_config.json")
        return fileManager.fileExists(atPath: weights.path)
            && fileManager.fileExists(atPath: config.path)
    }

    // MARK: - Config Parsing Helpers

    static func int(_ kwargs: [String: Any], _ key: String, _ fallback: Int) -> Int {
        if let v = kwargs[key] as? Int { return v }
        if let v = kwargs[key] as? Double { return Int(v) }
        if let v = kwargs[key] as? String, let i = Int(v) { return i }
        return fallback
    }

    static func bool(_ kwargs: [String: Any], _ key: String, _ fallback: Bool) -> Bool {
        if let v = kwargs[key] as? Bool { return v }
        if let v = kwargs[key] as? Int { return v != 0 }
        if let v = kwargs[key] as? Double { return v != 0 }
        if let v = kwargs[key] as? String {
            return ["1", "true", "yes"].contains(v.lowercased())
        }
        return fallback
    }

    static func double(_ kwargs: [String: Any], _ key: String, _ fallback: Double) -> Double {
        if let v = kwargs[key] as? Double { return v }
        if let v = kwargs[key] as? Int { return Double(v) }
        if let v = kwargs[key] as? String {
            if let d = Double(v) { return d }
            let parts = v.split(separator: "/")
            if parts.count == 2,
               let n = Double(parts[0]),
               let d = Double(parts[1]),
               d != 0 {
                return n / d
            }
        }
        return fallback
    }

    static func sources(_ kwargs: [String: Any]) -> [String] {
        (kwargs["sources"] as? [String]) ?? ["drums", "bass", "other", "vocals"]
    }
}
