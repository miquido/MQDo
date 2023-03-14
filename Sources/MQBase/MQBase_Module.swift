@_exported import MQ
@_exported import MQDo

extension FeaturesRegistry
where Scope == RootFeaturesScope {

	public mutating func useBaseFeatures() {
		self.use(SystemAsyncExecutor.self)
	}
}
