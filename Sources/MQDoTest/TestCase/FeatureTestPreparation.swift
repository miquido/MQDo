import MQDo

public final class FeatureTestPreparation {

	private let features: TestFeatures

	internal init(
		features: TestFeatures
	) {
		self.features = features
	}
}

#if DEBUG
	extension FeatureTestPreparation {

		/// Force given feature instance in container.
		///
		@Sendable public func callAsFunction<Feature>(
			use instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: StaticFeature {
			self.features
				.use(
					instance,
					file: file,
					line: line
				)
		}

		/// Force given feature instance in container.
		///
		@Sendable public func callAsFunction<Feature>(
			use instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DisposableFeature {
			self.features
				.use(
					instance,
					file: file,
					line: line
				)
		}

		/// Force given feature instance in container.
		///
		@Sendable public func callAsFunction<Feature>(
			use instance: Feature,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
			self.features
				.use(
					instance,
					file: file,
					line: line
				)
		}

		/// Force given feature instance in container.
		///
		@Sendable public func callAsFunction<Feature>(
			use instance: Feature,
			context: Feature.Context,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			self.features
				.use(
					instance,
					context: context,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature, Property>(
			patch keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: StaticFeature {
			self.features
				.patch(
					keyPath,
					with: updated,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature, Property>(
			patch keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DisposableFeature {
			self.features
				.patch(
					keyPath,
					with: updated,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature, Property>(
			patch keyPath: WritableKeyPath<Feature, Property>,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
			self.features
				.patch(
					keyPath,
					context: .void,
					with: updated,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature, Property>(
			patch keyPath: WritableKeyPath<Feature, Property>,
			context: Feature.Context,
			with updated: Property,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			self.features
				.patch(
					keyPath,
					context: context,
					with: updated,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature>(
			patch feature: Feature.Type,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: StaticFeature {
			self.features
				.patch(
					feature,
					with: update,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature>(
			patch feature: Feature.Type,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: DisposableFeature {
			self.features
				.patch(
					feature,
					with: update,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature>(
			patch feature: Feature.Type,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature, Feature.Context == CacheableFeatureVoidContext {
			self.features
				.patch(
					feature,
					context: .void,
					with: update,
					file: file,
					line: line
				)
		}

		/// Patch parts of overriden features.
		///
		@_disfavoredOverload @Sendable public func callAsFunction<Feature>(
			patch feature: Feature.Type,
			context: Feature.Context,
			with update: (inout Feature) -> Void,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Feature: CacheableFeature {
			self.features
				.patch(
					feature,
					context: context,
					with: update,
					file: file,
					line: line
				)
		}

		/// Set scope context.
		///
		@Sendable public func callAsFunction<Scope>(
			setContext context: Scope.Context,
			for scopeType: Scope.Type,
			file: StaticString = #fileID,
			line: UInt = #line
		) where Scope: FeaturesScope {
			self.features
				.use(
					context: context,
					for: scopeType,
					file: file,
					line: line
				)
		}
	}
#endif
