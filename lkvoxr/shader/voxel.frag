#pragma language glsl3

uniform vec3 camPos;
uniform vec3 camLookAt;
uniform float camFOV;
uniform vec2 screenSize;
uniform VolumeImage chunkConts;
uniform float renderDistHalf;
uniform float indTestAdd;

const int STEPS = 64;
const vec3 worldUp = vec3(0.0, -1.0, 0.0);


mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
	vec3 f = normalize(center - eye);
	vec3 s = normalize(cross(f, up));
	vec3 u = cross(s, f);
	return mat4(
		vec4(s, 0.0),
		vec4(u, 0.0),
		vec4(-f, 0.0),
		vec4(0.0, 0.0, 0.0, 1)
	);
}

struct hit {
    bool didHit;
    vec3 col;
};


//https://www.shadertoy.com/view/wdSBzK
hit getVoxel(vec3 p) {
    p.z = (renderDistHalf * 2) - p.z;
    vec3 sample = p.xzy;
    vec4 cont = Texel(chunkConts, sample / (vec3(renderDistHalf) * 2));

    if (cont.x != 0.0)
        return hit(true , vec3(0.5, 1.0, 0.5));
    else
        return hit(false, vec3(1.0, 0.0, 0.0));
}

vec3 lighting(vec3 norm, vec3 pos, vec3 rayDir, vec3 col) {
    vec3 lightDir = normalize(vec3(-1.0, 3.0, -1.0));
    float diffuseAttn = max(dot(norm, lightDir), 0.0);
    vec3 light = vec3(1.0,0.9,0.9);
    
    vec3 ambient = vec3(0.2, 0.2, 0.3);
    
    vec3 reflected = reflect(rayDir, norm);
    float specularAttn = max(dot(reflected, lightDir), 0.0);
    
    return col*(diffuseAttn*light*1.0 + specularAttn*light*0.6 + ambient);
}

// Voxel ray casting algorithm from "A Fast Voxel Traversal Algorithm for Ray Tracing" 
// by John Amanatides and Andrew Woo
// http://www.cse.yorku.ca/~amana/research/grid.pdf
hit intersect(vec3 rayPos, vec3 rayDir) {
    //Todo: find out why this is so slow
    vec3 pos = floor(rayPos);
    
    vec3 step = sign(rayDir);
    vec3 tDelta = step / rayDir;

    
    float tMaxX, tMaxY, tMaxZ;
    
    vec3 fr = fract(rayPos);
    
    tMaxX = tDelta.x * ((rayDir.x>0.0) ? (1.0 - fr.x) : fr.x);
    tMaxY = tDelta.y * ((rayDir.y>0.0) ? (1.0 - fr.y) : fr.y);
    tMaxZ = tDelta.z * ((rayDir.z>0.0) ? (1.0 - fr.z) : fr.z);

    vec3 norm;
    
    for (int i = 0; i < STEPS; i++) {
        hit h = getVoxel(ivec3(pos));
        if (h.didHit) {
            return hit(true, lighting(norm, pos, rayDir, h.col));
        }

        if (tMaxX < tMaxY) {
            if (tMaxZ < tMaxX) {
                tMaxZ += tDelta.z;
                pos.z += step.z;
                norm = vec3(0, 0,-step.z);
            } else {
                tMaxX += tDelta.x;
            	pos.x += step.x;
                norm = vec3(-step.x, 0, 0);
            }
        } else {
            if (tMaxZ < tMaxY) {
                tMaxZ += tDelta.z;
                pos.z += step.z;
                norm = vec3(0, 0, -step.z);
            } else {
            	tMaxY += tDelta.y;
            	pos.y += step.y;
                norm = vec3(0, -step.y, 0);
            }
        }
    }

 	return hit(false, vec3(0, 0, 1.0));
}



vec4 effect(vec4 color, Image tex, vec2 textureCoords, vec2 screenCoords) {
    /*
    vec2 uv = screenCoords / screenSize.xy;
    vec4 cont = Texel(chunkConts, vec3(uv.xy, indTestAdd));
    cont.w = 1;

    return cont;
    */


    vec2 uv = screenCoords / screenSize.xy - 0.5;

    vec3 camDir = normalize(camLookAt - camPos);
    vec3 camRight = normalize(cross(camDir, worldUp));
    vec3 camUp = cross(camRight, camDir);
    
    vec3 filmCentre = camPos + camDir*0.3;
    vec2 filmSize = vec2(1, screenSize.y / screenSize.x);
    
    vec3 filmPos = filmCentre + uv.x*filmSize.x*camRight + uv.y*filmSize.y*camUp;
    vec3 ro = fract(camPos) + (vec3(renderDistHalf)); //fract(camPos) - ivec3(renderDistHalf);
    vec3 rd = normalize(filmPos - camPos);


    hit data = intersect(ro, rd);
    if(data.didHit) {
        return vec4(data.col,1.0);
    } else{
        return vec4(0,0,0,1.0);
    }
}