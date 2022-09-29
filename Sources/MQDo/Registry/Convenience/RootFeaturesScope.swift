/// Root scope of all feature containers.
///
/// Scope type always used by root ``Features`` container instances.
/// It cannot be used as a container branch.
public enum RootFeaturesScope: FeaturesScope {

	// swift-format-ignore: AllPublicDeclarationsHaveDocumentation
	public typealias Context = Never
}
