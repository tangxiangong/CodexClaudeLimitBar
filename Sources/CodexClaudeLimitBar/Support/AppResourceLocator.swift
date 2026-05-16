import Foundation

enum AppResourceLocator {
    static func url(
        forResource name: String,
        withExtension fileExtension: String,
        subdirectory: String? = nil
    ) -> URL? {
        let mainNestedURL = Bundle.main.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: subdirectory
        )
        let mainRootURL = Bundle.main.url(forResource: name, withExtension: fileExtension)

        if let url = mainNestedURL ?? mainRootURL {
            return url
        }

        let moduleRootURL = Bundle.module.url(forResource: name, withExtension: fileExtension)
        let moduleNestedURL = Bundle.module.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: subdirectory
        )

        return moduleRootURL ?? moduleNestedURL
    }
}
