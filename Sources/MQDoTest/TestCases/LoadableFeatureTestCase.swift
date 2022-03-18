import MQDo
import XCTest

open class LoadableFeatureTestCase<Feature: LoadableFeature>: XCTestCase {

  open class var loader: FeatureLoader<Feature> {
    unimplemented("You have to provide loader for tested feature")
  }
  open class var defaultContext: Feature.Context? { .none }

  public final var testFeatures: Features {
    get {
      if let features: Features = self.features {
        return features
      }
      else {
        let features: Features = .testing(
          Feature.self,
          Self.loader
        )
        self.features = features
        return features
      }
    }
    set {
      self.features = newValue
    }
  }
  public final var testedFeatureContext: Feature.Context {
    get {
      if let context: Feature.Context = self.testedInstanceContext {
        return context
      }
      else if let defaultContext: Feature.Context = Self.defaultContext {
        self.testedInstanceContext = defaultContext
        return defaultContext
      }
      else {
        unimplemented("You have to provide default feature context or provide context manually")
      }
    }
    set {
      self.testedInstanceContext = newValue
    }
  }
  public final var testedFeature: Feature {
    if let feature: Feature = self.testedInstance {
      return feature
    }
    else {
      do {
        let feature: Feature = try self.testFeatures.instance(
          of: Feature.self,
          context: self.testedFeatureContext
        )
        self.testedInstance = feature
        return feature
      }
      catch {
        error
          .asTheError()
          .asFatalError()
      }
    }
  }
  private var testedInstanceContext: Feature.Context?
  private var testedInstance: Feature?
  private var features: Features?

  open override func tearDown() {
    self.features = nil
    self.testedInstance = nil
    self.testedInstanceContext = nil

    super.tearDown()
  }
}

extension LoadableFeatureTestCase {

  public func patch<Feature, Property>(
    _ keyPath: WritableKeyPath<Feature, Property>,
    context: Feature.Context,
    with updated: Property,
    file: StaticString = #fileID,
    line: UInt = #line
  ) where Feature: LoadableFeature, Feature.Context: IdentifiableFeatureContext
  {
    self.testFeatures
      .patch(
        keyPath,
        context: context,
        with: updated,
        file: file,
        line: line
      )
  }

  public func patch<Feature, Property, Tag>(
    _ keyPath: WritableKeyPath<Feature, Property>,
    with updated: Property,
    file: StaticString = #fileID,
    line: UInt = #line
  ) where Feature: LoadableFeature, Feature.Context == TagFeatureContext<Tag>
  {
    self.testFeatures
      .patch(
        keyPath,
        with: updated,
        file: file,
        line: line
      )
  }

// TODO: wait for: https://github.com/miquido/MQDo/pull/5
//  @_disfavoredOverload
//  public func patch<Feature, Property>(
//    _ keyPath: WritableKeyPath<Feature, Property>,
//    with updated: Property,
//    file: StaticString = #fileID,
//    line: UInt = #line
//  ) where Feature: LoadableFeature
//  {
//    self.testFeatures
//      .patch(
//        keyPath,
//        with: updated,
//        file: file,
//        line: line
//      )
//  }
}
