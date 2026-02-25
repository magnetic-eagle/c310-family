$FG_GLSL_VERSION

/*#version 130
#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2

uniform float diameter;

varying vec4 vertex;
varying vec4 diffuse_term;
varying vec3 normal;

uniform int colorMode;

void setupShadows(vec4 eyeSpacePos);

void main() {
	vertex = gl_Vertex;
	vertex.yz *= diameter;
	gl_Position = gl_ModelViewProjectionMatrix * vertex;
	gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	normal = gl_NormalMatrix * gl_Normal;
	vec4 ambient_color, diffuse_color;
	if (colorMode == MODE_DIFFUSE) {
		diffuse_color = gl_Color;
		ambient_color = gl_FrontMaterial.ambient;
	} else if (colorMode == MODE_AMBIENT_AND_DIFFUSE) {
		diffuse_color = gl_Color;
		ambient_color = gl_Color;
	} else {
		diffuse_color = gl_FrontMaterial.diffuse;
		ambient_color = gl_FrontMaterial.ambient;
	}
	diffuse_term = diffuse_color * gl_LightSource[0].diffuse;
	vec4 constant_term = gl_FrontMaterial.emission + ambient_color *
						(gl_LightModel.ambient +  gl_LightSource[0].ambient);
	// Super hack: if diffuse material alpha is less than 1, assume a
	// transparency animation is at work
	if (gl_FrontMaterial.diffuse.a < 1.0) {
		diffuse_term.a = gl_FrontMaterial.diffuse.a;
	} else {
		diffuse_term.a = gl_Color.a;
	}
	// Another hack for supporting two-sided lighting without using
	// gl_FrontFacing in the fragment shader.
	gl_FrontColor.rgb = constant_term.rgb;  gl_FrontColor.a = 1.0;
	gl_BackColor.rgb = constant_term.rgb; gl_BackColor.a = 0.0;
	setupShadows(vertex);
}*/

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec4 multitexcoord0;

out VS_OUT {
    float flogz;
    vec2 texcoord;
    vec3 vertex_normal;
    vec3 view_vector;
    vec4 ap_color;
    vec3 vertex;
} vs_out;

uniform float diameter;

uniform mat4 osg_ModelViewMatrix;
uniform mat4 osg_ModelViewProjectionMatrix;
uniform mat3 osg_NormalMatrix;
uniform mat4 fg_TextureMatrix;

// aerial_perspective.glsl
vec4 get_aerial_perspective(vec2 raw_coord, vec3 P);
// logarithmic_depth.glsl
float logdepth_prepare_vs_depth(float z);

void main() {
	vec4 vertex = pos;
	vertex.yz *= diameter;
	vs_out.vertex = vertex.xyz;
	gl_Position = osg_ModelViewProjectionMatrix * vertex;
	vs_out.flogz = logdepth_prepare_vs_depth(gl_Position.w);
	vs_out.texcoord = vec2(fg_TextureMatrix * multitexcoord0);

	vs_out.vertex_normal = osg_NormalMatrix * normal;
	vs_out.view_vector = (osg_ModelViewMatrix * pos).xyz;

	vec2 raw_coord = (gl_Position.xy / gl_Position.w) * 0.5 + 0.5;
	vs_out.ap_color = get_aerial_perspective(raw_coord, vs_out.view_vector);
}
