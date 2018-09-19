//
//  Particle.metal
//  ParticlesOC
//
//  Created by roselzy on 2018/9/3.
//  Copyright © 2018 Rose LZY. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void particleRendererShader(texture2d<float, access::write> outTexture [[texture(0)]],
                                   const device float4 *inParticles [[buffer(0)]],
                                   device float4 *outParticles [[buffer(1)]],
                                   const device float4 *originParticles [[buffer(2)]],
                                   constant float &imageWidth [[buffer(3)]],
                                   constant float &imageHeight [[buffer(4)]],
                                   device float3 &particleColor [[buffer(5)]],
                                   constant float &duration [[buffer(6)]],
                                   const device float4 *dislocationInParticles [[buffer(7)]],
                                   device int &inFinishHoming [[buffer(8)]],
                                   device int &inFinishDiffused [[buffer(9)]],
                                   constant int &finishType [[buffer(10)]],
                                   const device int &startDiffuseFlag [[buffer(11)]],
                                   const device float &randomDisplacement [[buffer(12)]],
                                   uint id [[thread_position_in_grid]]) {
    const float4 inParticle = inParticles[id];
    const float4 dislocationParticle = dislocationInParticles[id];
    const float4 originParticle = originParticles[id];
    const float inParticleZ = inParticle.z;
    const float inParticleW = inParticle.w;
    
    const uint2 particlePositionA(inParticle.x, inParticle.y);
    const float2 inParticlePosition(inParticle.x, inParticle.y);
    const float2 dislocationParticlePosition(dislocationParticle.x, dislocationParticle.y);
    const float2 originParticlesPosition(originParticle.x, originParticle.y);         
    float currentDistance = fabs(distance(originParticlesPosition, inParticlePosition));
    float currentDislocationDistance = fabs(distance(dislocationParticlePosition, inParticlePosition));
    float alpha = float(1) - currentDistance / fabs(distance(originParticlesPosition, dislocationParticlePosition));
    float4 outColor = float4(particleColor.x * alpha, particleColor.y * alpha, particleColor.z * alpha, alpha);
    
    float destinationX;
    float destinationY;
    float slope;
    float b;
    float stepDistance;
    float distance_between_origin_dislocation_particles;
    
    if (finishType not_eq 2) { // not diffuse effect
        if (particlePositionA.x > 0 && particlePositionA.y > 0 && particlePositionA.x < imageWidth && particlePositionA.y < imageHeight) {
            outTexture.write(outColor, particlePositionA);
        }
        distance_between_origin_dislocation_particles = abs(distance(dislocationParticlePosition, originParticlesPosition)) / duration / 60;
        if (inFinishHoming == 1) {
            if (finishType == 1) {
                float fid = float(id);
                // do some shake effect
                destinationX = originParticle.x + randomDisplacement * sin(fid) * 3 * randomDisplacement;
                destinationY = originParticle.y + randomDisplacement * cos(fid) * 3 * randomDisplacement;
            }else if (finishType == 0) {
                destinationX = inParticle.x;
                destinationY = inParticle.y;
            }
        }else {
            if (inParticle.x == originParticle.x) { // slope is near to +inf or -inf
                float distance_only_y_axis = abs(dislocationParticlePosition.y - originParticlesPosition.y) / duration / 60;
                destinationX = inParticle.x;
                if (inParticle.y > originParticle.y) {
                    destinationY = inParticle.y - distance_only_y_axis;
                }else {
                    destinationY = inParticle.y + distance_only_y_axis;
                }
            }else {
                if (((inParticle.x < originParticle.x) and (inParticle.y < originParticle.y)) or ((inParticle.x > originParticle.x) and (inParticle.y > originParticle.y))) {
                    // slope is negative
                    slope = (originParticle.y - inParticle.y) / (inParticle.x - originParticle.x);
                    stepDistance = sqrt(pow(distance_between_origin_dislocation_particles, 2) / (pow(slope, 2) + 1));
                    b = originParticle.y - slope * originParticle.x;
                    if (inParticle.x < originParticle.x) {
                        destinationX = inParticle.x + stepDistance;
                    }else {
                        destinationX = inParticle.x - stepDistance;
                    }
                    destinationY = slope * destinationX + b;
                }else {
                    // slope is positive
                    slope = (inParticle.y - originParticle.y) / (originParticle.x - inParticle.x);
                    stepDistance = sqrt(pow(distance_between_origin_dislocation_particles, 2) / (pow(slope, 2) + 1));
                    b = originParticle.y - slope * originParticle.x;
                    if (inParticle.x < originParticle.x) {
                        destinationX = inParticle.x + stepDistance;
                    }else {
                        destinationX = inParticle.x - stepDistance;
                    }
                    destinationY = slope * destinationX + b;
                }
            }
        }
    }else { // diffuse effect
        if (inFinishHoming == 0 or startDiffuseFlag == 0) { // back to origin location animation is not finish
            if (particlePositionA.x > 0 && particlePositionA.y > 0 && particlePositionA.x < imageWidth && particlePositionA.y < imageHeight) {
                outTexture.write(outColor, particlePositionA);
            }
            distance_between_origin_dislocation_particles = abs(distance(dislocationParticlePosition, originParticlesPosition)) / duration / 60;
            if (inParticle.x == originParticle.x) { // slope is near to +inf or -inf
                float distance_only_y_axis = abs(dislocationParticlePosition.y - originParticlesPosition.y) / duration / 60;
                destinationX = inParticle.x;
                if (inParticle.y > originParticle.y) {
                    destinationY = inParticle.y - distance_only_y_axis;
                }else {
                    destinationY = inParticle.y + distance_only_y_axis;
                }
            }else {
                if (((inParticle.x < originParticle.x) and (inParticle.y < originParticle.y)) or ((inParticle.x > originParticle.x) and (inParticle.y > originParticle.y))) {
                    // slope is negative
                    slope = (originParticle.y - inParticle.y) / (inParticle.x - originParticle.x);
                    stepDistance = sqrt(pow(distance_between_origin_dislocation_particles, 2) / (pow(slope, 2) + 1));
                    b = originParticle.y - slope * originParticle.x;
                    if (inParticle.x < originParticle.x) {
                        destinationX = inParticle.x + stepDistance;
                    }else {
                        destinationX = inParticle.x - stepDistance;
                    }
                    destinationY = slope * destinationX + b;
                }else {
                    // slope is positive
                    slope = (inParticle.y - originParticle.y) / (originParticle.x - inParticle.x);
                    stepDistance = sqrt(pow(distance_between_origin_dislocation_particles, 2) / (pow(slope, 2) + 1));
                    b = originParticle.y - slope * originParticle.x;
                    if (inParticle.x < originParticle.x) {
                        destinationX = inParticle.x + stepDistance;
                    }else {
                        destinationX = inParticle.x - stepDistance;
                    }
                    destinationY = slope * destinationX + b;
                }
            }
        }else { // 扩散动画
            alpha = currentDislocationDistance / fabs(distance(originParticlesPosition, dislocationParticlePosition));
            outColor = float4(particleColor.x * alpha, particleColor.y * alpha, particleColor.z * alpha, alpha);
            if (particlePositionA.x > 0 && particlePositionA.y > 0 && particlePositionA.x < imageWidth && particlePositionA.y < imageHeight) {
                outTexture.write(outColor, particlePositionA);
            }
            if (startDiffuseFlag == 1) {
                distance_between_origin_dislocation_particles = fabs(distance(dislocationParticlePosition, originParticlesPosition)) / 1.0 / 60.0;
                if (inParticle.x == dislocationParticle.x) { // slope is near to +inf or -inf
                    float distance_only_y_axis = fabs(dislocationParticlePosition.y - originParticlesPosition.y) / 1.0 / 60.0; // 一秒为时长，每次刷新移动的距离
                    destinationX = inParticle.x;
                    if (inParticle.y > dislocationParticle.y) {
                        destinationY = inParticle.y - distance_only_y_axis;
                    }else {
                        destinationY = inParticle.y + distance_only_y_axis;
                    }
                }else {
                    if (((inParticle.x < dislocationParticle.x) and (inParticle.y < originParticle.y)) or ((inParticle.x > dislocationParticle.x) and (inParticle.y > dislocationParticle.y))) {
                        // slope is negative
                        slope = (dislocationParticle.y - inParticle.y) / (inParticle.x - dislocationParticle.x);
                        stepDistance = sqrt(pow(distance_between_origin_dislocation_particles, 2) / (pow(slope, 2) + 1));
                        b = dislocationParticle.y - slope * dislocationParticle.x;
                        if (inParticle.x < dislocationParticle.x) {
                            destinationX = inParticle.x + stepDistance;
                        }else {
                            destinationX = inParticle.x - stepDistance;
                        }
                        destinationY = slope * destinationX + b;
                    }else {
                        // slope is positive
                        slope = (inParticle.y - dislocationParticle.y) / (dislocationParticle.x - inParticle.x);
                        stepDistance = sqrt(pow(distance_between_origin_dislocation_particles, 2) / (pow(slope, 2) + 1));
                        b = dislocationParticle.y - slope * dislocationParticle.x;
                        if (inParticle.x < dislocationParticle.x) {
                            destinationX = inParticle.x + stepDistance;
                        }else {
                            destinationX = inParticle.x - stepDistance;
                        }
                        destinationY = slope * destinationX + b;
                    }
                }
            }else {
                destinationX = inParticle.x;
                destinationY = inParticle.y;
            }
        }
    }
    float4 outParticle;
    outParticle = {destinationX, destinationY, inParticleZ, inParticleW};
    outParticles[id] = outParticle;
}
