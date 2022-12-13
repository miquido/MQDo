@_exported import MQ
@_exported import MQDo

extension FeaturesRegistry where Scope == RootFeaturesScope {

	public mutating func useBaseFeatures() {
		if #available(iOS 14.0, *) {
			self.use(static: Diagnostics.osDiagnostics)
		}
		else {
			self.use(static: Diagnostics.disabled)
		}
		self.use(AsyncExecutor.systemExecutor())
	}
}
