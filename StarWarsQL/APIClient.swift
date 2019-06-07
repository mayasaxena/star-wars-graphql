//
//  APIClient.swift
//  StarWarsQL
//
//  Created by Maya Saxena on 6/7/19.
//  Copyright © 2019 Maya Saxena. All rights reserved.
//

import Foundation

enum APIError: Error {
    case http(statusCode: Int)
    case noResponse
    case unknown(message: String?)
}


// { "query" : "{ allPlanets { name climate terrain } }" }
struct Planet: Codable {
    let name: String
    let climate: [String]?
    let terrain: [String]?
}

struct AllPlanetsQuery: Decodable {
    let planets: [Planet]

    enum CodingKeys: String, CodingKey {
        case data
        case allPlanets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let allPlanetsContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        planets = try allPlanetsContainer.decode([Planet].self, forKey: .allPlanets)
    }
}

struct APIClient {

    func test() {
        var request = URLRequest(url: URL(string: "https://api.graphcms.com/simple/v1/swapi")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: String] = [
            "query" : "{ allPlanets { name climate terrain }  }"
        ]

        request.httpBody = try! JSONSerialization.data(withJSONObject: json, options: [])

        send(urlRequest: request) { result in
            let jsonData = try! result.get()

            let allPlanetsQuery = try! JSONDecoder().decode(AllPlanetsQuery.self, from: jsonData)
            print(allPlanetsQuery.planets)
        }
    }

    private func send(urlRequest: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.unknown(message: nil)))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noResponse))
                return
            }

            let statusCode = httpResponse.statusCode
            switch statusCode {
            case 200..<300:
                completion(.success(data))
            default:
                let error = APIError.http(statusCode: statusCode)
                completion(.failure(error))
            }
        }

        dataTask.resume()
    }
}
