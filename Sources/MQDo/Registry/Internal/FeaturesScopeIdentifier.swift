internal struct FeaturesScopeIdentifier {

	internal let scope: FeaturesScope.Type
	private let identifier: ObjectIdentifier

	internal init<Scope>(
		scope: Scope.Type
	) where Scope: FeaturesScope {
		self.scope = scope
		self.identifier = .init(scope)
	}
}

extension FeaturesScopeIdentifier: Sendable {}

extension FeaturesScopeIdentifier: Hashable {

	internal static func == (
		_ lhs: FeaturesScopeIdentifier,
		_ rhs: FeaturesScopeIdentifier
	) -> Bool {
		lhs.identifier == rhs.identifier
	}

	internal func hash(
		into hasher: inout Hasher
	) {
		hasher.combine(self.identifier)
	}
}

extension FeaturesScopeIdentifier: CustomStringConvertible {

	internal var description: String {
		"Scope:\(self.scope)"
	}
}

extension FeaturesScopeIdentifier: CustomDebugStringConvertible {

	internal var debugDescription: String {
		"Scope:\(self.scope)"
	}
}

extension FeaturesScopeIdentifier: CustomLeafReflectable {

	internal var customMirror: Mirror {
		.init(
			self,
			children: [],
			displayStyle: .none
		)
	}
}
