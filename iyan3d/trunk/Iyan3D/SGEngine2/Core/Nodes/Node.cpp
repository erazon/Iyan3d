//
//  Node.cpp
//  SGEngine2
//
//  Created by Harishankar on 14/11/14.
//  Copyright (c) 2014 Smackall Games Pvt Ltd. All rights reserved.
//

#include "Node.h"
#ifdef IOS
#import "TargetConditionals.h"
#endif
Node::Node() {
    skinType = GPU_SKIN;
    id = NOT_EXISTS;
    type = NODE_TYPE_EMPTY;
    needsVertexColor = shouldUpdateMesh = false;
    needsVertexNormal = false;
    needsVertexPosition = true;
    needsIndexBuf = true;
    position = Vector3(0.0);
    rotation = Vector3(0.0);
    scale = Vector3(1.0);
    activeTextureIndex = 0;
    for(int i = 0;i < MAX_TEXTURE_PER_NODE;i++)
        textures[i] = NULL;
    //Parent = NULL;
    Children = make_shared< vector< shared_ptr<Node> > >();
    this->instancedNodes = make_shared< vector< shared_ptr<InstanceNode> > >();
    textureCount = instanceCount = 0;
    updateTransformation = false;
    isVisible = true;
    #ifdef ANDROID
    nodeData = make_shared<OGLNodeData>();
    #elif IOS
    if(common::deviceType == OPENGLES2)
        nodeData = make_shared<OGLNodeData>();
    else{
        #if !(TARGET_IPHONE_SIMULATOR)
            nodeData = static_pointer_cast<APIData>(initMetalNodeData());
        #endif
    }
    #endif
    drawMode = DRAW_MODE_TRIANGLES;
}
Node::~Node() {
    if(this->instancedNodes->size()){
        for(u16 i = 0;i < instancedNodes->size();i++){
            if((*instancedNodes)[i]) {
                (*instancedNodes)[i].reset();
                instancedNodes->erase(instancedNodes->begin() + i);
            }
        }
    }
    this->instancedNodes->clear();
    if(this->instancedNodes)
        this->instancedNodes.reset();

    
    if(this->Children->size()){
        for(u16 i = 0;i < Children->size();i++){
            if((*Children)[i]) {
                (*Children)[i].reset();
                Children->erase(Children->begin() + i);
            }
        }
    }
    this->Children->clear();
    if(this->Children)
        this->Children.reset();
    
    if(this->Parent)
    this->Parent.reset();
    
    if(nodeData)
        nodeData.reset();
}
bool Node::operator==(shared_ptr<Node> n) {
    if(n->getID() != id || n->position != position || n->scale != scale || n->rotation != rotation || n->callbackFuncName.compare(callbackFuncName) != 0 || n->type != type)
        return false;
    return true;
}
bool Node::isMetalSupported(){
    #ifdef IOS
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);
    
    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
    if(subtype == CPU_SUBTYPE_ARM64_V8)
        return true;
    return false;
    #endif
}
void Node::setTexture(Texture *texture,int textureIndex){
    if(textureIndex > MAX_TEXTURE_PER_NODE){
        Logger::log(ERROR, "OGLNodeData", "Texture Index crossed maximum index limit");
        return;
    }
    if(textures[textureIndex-1] == NULL)
        textureCount++;
    textures[textureIndex-1] = texture;
}
void Node::setRotationInDegrees(Vector3 rotation){
    this->rotation = Vector3(rotation.x * (PI/180.0),rotation.y * (PI/180.0),rotation.z * (PI/180.0));
    FlagTransformationToChildren();
}
void Node::setRotationInRadians(Vector3 rotation){
    this->rotation = rotation;
    FlagTransformationToChildren();
}
void Node::setPosition(Vector3 position){
    this->position = position;
    FlagTransformationToChildren();
}
void Node::setScale(Vector3 scale){
    this->scale = scale;
    FlagTransformationToChildren();
}
Vector3 Node::getRotationInRadians(){
    return rotation;
}
Vector3 Node::getRotationInDegrees(){
    return rotation * (180.0/PI);
}
Vector3 Node::getPosition(){
    return position;
}
Vector3 Node::getScale(){
    return scale;
}
Vector3 Node::getAbsolutePosition()
{
    return getAbsoluteTransformation().getTranslation();
}
void Node::updateAbsoluteTransformation(bool updateFromRoot){
    if(Parent){
        AbsoluteTransformation = Parent->getAbsoluteTransformation() * getRelativeTransformation();
      //  updateTransformation = false;
    }else {
        AbsoluteTransformation = getRelativeTransformation();
    }
}
void Node::updateAbsoluteTransformationOfChildren(){
    updateAbsoluteTransformation();
    if(Children->size()){
        for(unsigned short i = 0; i < Children->size();i++){
            if((*Children)[i])
                (*Children)[i]->updateAbsoluteTransformation();
        }
    }
}
Mat4 Node::getAbsoluteTransformation(){
//    if(updateTransformation)
        updateAbsoluteTransformation();
    return AbsoluteTransformation;
}
void Node::updateRelativeTransformation(){
  }
Mat4 Node::getRelativeTransformation(){
    Mat4 localMat;
    localMat.translate(position);
    localMat.setRotationRadians(rotation);
    if(scale != Vector3(1.0f)){
        localMat.scale(scale);
    }
    return localMat;
}
Mat4 Node::getModelMatrix(){
    return getAbsoluteTransformation();
}
void Node::FlagTransformationToChildren(){
    updateTransformation = true;
    if(Children->size())
        return (*Children)[0]->FlagTransformationToChildren();
    return;
}
Texture* Node::getTextureByIndex(u16 textureIndex){
    if(textureIndex > MAX_TEXTURE_PER_NODE || textureIndex <= 0 || textureIndex > textureCount){
        return NULL;
    }
    return textures[textureIndex - 1];
}
Texture* Node::getActiveTexture(){
    if(textureCount < 1)
        return NULL;
    return textures[activeTextureIndex];
}
shared_ptr<InstanceNode> Node::getNodeInstanceByIndex(u16 index){
    
    return (*this->instancedNodes)[index];
}
bool Node::CreateNodeInstance(u16 instanceCount){
    if(type <= NODE_TYPE_CAMERA || type == NODE_TYPE_LIGHT || type == NODE_TYPE_LIGHT)
        return false;
    this->instanceCount = instanceCount;
    for(u16 i = 0;i < instanceCount;i++){
        shared_ptr<InstanceNode> INode = shared_ptr<InstanceNode>(new InstanceNode());
        this->instancedNodes->push_back(INode);
    }
    return true;
}
void Node::RemoveNodeInstanceByIndex(u16 index){
    this->instancedNodes->erase(this->instancedNodes->begin() + index);
    instanceCount--;
}
void Node::RemoveAllInstanceOfNode(){
    this->instancedNodes->clear();
    instanceCount = 0;
}
void Node::setMaterial(Material *mat,bool isTransparentMaterial){
    this->material = mat;
    this->material->isTransparent = isTransparentMaterial;
}
u16 Node::getBufferCount(){
    if(type == NODE_TYPE_MORPH || type== NODE_TYPE_MORPH_SKINNED)
        return 2;
    return 1;
}
void Node::setID(int id){
    this->id = id;
}
int Node::getID(){
    return id;
}
void Node::setParent(shared_ptr<Node> parent)
{
    if(this->Parent && this->Parent->Children && this->Parent->Children->size() > 0) { // remove from child list of previous parent
        for(int i = 0; i < this->Parent->Children->size();i++){
            if((*this->Parent->Children)[i] && (*this->Parent->Children)[i]->getID() == id){
                (this->Parent->Children)->erase(this->Parent->Children->begin() + i);
                this->Parent.reset();
                break;
            }
        }
    }
    if(this->Parent && parent && this->Parent->getID() == parent->getID()) // returns if present parent is same
           return;
    this->Parent = parent;
    if(parent)
        this->Parent->Children->push_back(shared_from_this());
}
shared_ptr<Node> Node::getParent(){
    return Parent;
}
void Node::setVisible(bool isVisible)
{
    this->isVisible = isVisible;
}
bool Node::getVisible(){
    return isVisible;
}
int Node::getTextureCount()
{
    return textureCount;
}
void Node::detachFromParent(){
    if(getParent()){
        for(int c = 0;c < getParent()->Children->size();c++){
            if((*getParent()->Children)[c]->getID() == getID()){
                getParent()->Children->erase(getParent()->Children->begin() + c);
                return;
            }
        }
    }
}
void Node::detachAllChildren(){
    for(int c = 0;c < Children->size();c++)
        (*Children)[c]->setParent(shared_ptr<Node>());
    Children->clear();
}


