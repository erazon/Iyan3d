//
//  SGCircleNode.h
//  SGEngine2
//
//  Created by Harishankar on 14/11/14.
//  Copyright (c) 2014 Smackall Games Pvt Ltd. All rights reserved.
//

#ifndef __SGEngine2__SGCircleNode__
#define __SGEngine2__SGCircleNode__

#include "../common/common.h"

#include "../Nodes/MeshNode.h"
#include "../../Loaders/CSGRMeshFileLoader.h"

class SGCircleNode : public MeshNode {
    
public:
    SGCircleNode(int noOfVertices,int radius);
    ~SGCircleNode();
    void update();
};

#endif /* defined(__SGEngine2__CubeMeshNode__) */
