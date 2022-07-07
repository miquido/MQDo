internal struct AnyLoadableFeatureContextIdentifier: @unchecked Sendable {

	private let value: AnyHashable

	internal init<Value>(
		_ value: Value
	)
	where Value: Hashable & Sendable {
		self.value = value
	}
}

extension AnyLoadableFeatureContextIdentifier: Hashable {}
