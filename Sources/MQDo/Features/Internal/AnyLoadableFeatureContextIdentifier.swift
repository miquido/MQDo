internal struct AnyDynamicFeatureContextIdentifier {

	private let value: AnyHashable

	internal init<Value>(
		_ value: Value
	)
	where Value: Hashable & Sendable {
		self.value = value
	}
}

extension AnyDynamicFeatureContextIdentifier: @unchecked Sendable {}
extension AnyDynamicFeatureContextIdentifier: Hashable {}
