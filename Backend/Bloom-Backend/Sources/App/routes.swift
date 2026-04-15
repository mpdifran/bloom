import Vapor

// Register routes
func routes(_ app: Application) throws {
  try app.register(collection: AppSiteAssociationController(app: app))
  try app.register(collection: UserController())
  try app.register(collection: FoodController())
  try app.register(collection: ChatController())
  try app.register(collection: GoalController())
  try app.register(collection: AdminAuthenticationController())
  try app.register(collection: AdminFoodController())
  try app.register(collection: AdminOpenAIController())
  try app.register(collection: AdminChatController())
  try app.register(collection: AdminStorageController())
  try app.register(collection: HealthReportController())
  try app.register(collection: WorkoutController())
  try app.register(collection: SalesController())
  try app.register(collection: AdminSalesController())

  try app.register(collection: AdminMailerLiteController())
  try app.register(collection: RevenueCatWebhookController())

  // IMPORTANT: Fallback controller must be registered LAST
  // to avoid catching API endpoints
  try app.register(collection: FallbackController(app: app))
}
