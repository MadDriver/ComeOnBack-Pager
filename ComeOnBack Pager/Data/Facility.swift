//
//  ComeOnBack Pager
//
//  Created by user on 1/21/24.
//

import Foundation

struct Facility: Hashable, Codable {
    var name: String
    var areas: [Area]
    var controllers: [Controller]
}

extension Facility {
    func getArea(forController controller: Controller) -> Area? {
        return areas.first { area in
            area.name == controller.areaString
        }
    }
}
