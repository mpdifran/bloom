import Vapor

// Register routes
func routes(_ app: Application) throws {
  try app.register(collection: UserController())
  try app.register(collection: FoodController())
  try app.register(collection: ChatController())
  try app.register(collection: GoalController())
  try app.register(collection: AdminAuthenticationController())
  try app.register(collection: AdminFoodController())
  try app.register(collection: AdminOpenAIController())
  try app.register(collection: AdminChatController())
  try app.register(collection: HealthReportController())
}
