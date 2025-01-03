import Vapor

// Register routes
func routes(_ app: Application) throws {
  try app.register(collection: AuthenticationController())
  try app.register(collection: FoodController())
  try app.register(collection: AdminFoodController())
}
