//
//  Mat4.h
//  SGEngine2
//
//  Created by Harishankar on 13/11/14.
//  Copyright (c) 2014 Smackall Games Pvt Ltd. All rights reserved.
//

#ifndef __SGEngine2__Mat4__
#define __SGEngine2__Mat4__

#include "Vector4.h"

#ifdef ANDROID
#include "Utilities/Maths.h"
#elif IOS
#include "Maths.h"
#elif UBUNTU
#include "Maths.h"
#include <string.h>
#endif

class Mat4 {

public:
    float c[16]; // Matrix components, in column-major order
    Mat4();
    Mat4(float* pMat);
    Mat4(const Vector3& axis_x, const Vector3& axis_y, const Vector3& axis_z, const Vector3& trans);
    ~Mat4();

    Mat4& operator=(const Mat4& m);
    bool operator==(const Mat4& m) const;
    Mat4& operator*=(const Mat4& m);
    Mat4 operator*(const Mat4& m) const;
    Vector4 operator*(const Vector4& v) const;

    float& operator[](unsigned i);
    float operator[](unsigned i) const;

    void perspective(float fov, float aspect, float nearz, float farz);
    void ortho(float left, float right, float top, float bottom, float nearz, float farz);
    void translate(float x, float y, float z);
    void translate(const Vector3& v);
    void scale(float x, float y, float z);
    void scale(const Vector3& v);
    void scale(float s);
    void rotate(float angle, int axis);
    void copyMatTo(float *pointer);
    //    void rotate(const Quaternion &q);
    void setRotationRadians(Vector3 rotation);
    void bias();
    bool invert();
    void transpose();
    float* pointer();
    void buildCameraLookAtMatrixLH(Vector3 position, Vector3 target, Vector3 upVector);
    void buildProjectionMatrixPerspectiveFovLH(float fieldOfViewRadians, float aspectRatio, float zNear, float zFar);
    Vector3 getTranslation();
    Vector3 getRotationInDegree();
    Vector3 getRotation();
    Vector3 getScale();
    Mat4 setbyproduct(Mat4& other_a, Mat4& other_b);
    void rotateVect(Vector3& vect) const;
};

#endif /* defined(__SGEngine2__Mat4__) */