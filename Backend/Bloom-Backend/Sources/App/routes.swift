import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: FoodController(app: app))
}
