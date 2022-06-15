import MQDo
import XCTest

public typealias ContextlessLoadableFeatureTestCase<Feature> = TaggedLoadableFeatureTestCase<Feature>
where Feature: TaggedLoadableFeature, Feature.Context == Never

open class TaggedLoadableFeatureTestCase<Feature: TaggedLoadableFeature>: LoadableFeatureTestCase<Feature> {

  public final override class var defaultContext: Feature.Context? {
    .context
  }
}
