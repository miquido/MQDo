internal struct AnyIdentifiableFeatureContextIdentifier {

	private let value: AnyHashable

	internal init<Value>(
		_ value: Value
	) where Value: Hashable & Sendable {
		self.value = value
	}
}

extension AnyIdentifiableFeatureContextIdentifier: @unchecked Sendable {}
extension AnyIdentifiableFeatureContextIdentifier: Hashable {}
