// RasteriCEr
// https://github.com/ToNi3141/RasteriCEr
// Copyright (c) 2021 ToNi3141

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#ifndef ICEGL_HPP
#define ICEGL_HPP

#include <vector>
#include <array>
#include "IRenderer.hpp"
#include "TnL.hpp"
#include "Vec.hpp"
#include "IceGLTypes.h"

//#define CLIP_UNITCUBE

class IceGL
{
public:
    IceGL(IRenderer& renderer);

    void glMatrixMode(GLenum mm);
    void glMultMatrixf(const GLfloat* m);
    void glMultMatrixd(const GLdouble* m);
    void glTranslatef(GLfloat x, GLfloat y, GLfloat z);
    void glRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
    void glScalef(GLfloat x, GLfloat y, GLfloat z);
    void glLoadIdentity();
    void glOrthof(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top, GLfloat near, GLfloat far);
    void glViewport(GLint x, GLint y, GLsizei width, GLsizei height);
    void glDepthRange(GLclampd zNear, GLclampd zFar);
    void glBegin(GLenum mode);
    void glEnd();
    void glRect(GLfloat x1, GLfloat y1, GLfloat x2, GLfloat y2);
    void glVertex2f(GLfloat x, GLfloat y);
    void glVertex3f(GLfloat x, GLfloat y, GLfloat z);
    void glNormal3f(GLfloat nx, GLfloat ny, GLfloat nz);
    void glTexCoord2f(GLfloat s, GLfloat t);
    void glTexGeni(GLenum coord, GLenum pname, GLint param);
    void glTexGenfv(GLenum coord, GLenum pname, const GLfloat* param);
    void glColor4f(	GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
    void glColor4ub(GLubyte red, GLubyte green, GLubyte blue, GLubyte alpha);
    void glColor3f(	GLfloat red, GLfloat green, GLfloat blue);
    void glColor3ub(GLubyte red, GLubyte green, GLubyte blue);
    void glColor3dv(const GLdouble* v);
    void glColor4dv(const GLdouble* v);
    void glColor4fv(const GLfloat* v);
    void glVertexPointer(GLint size, GLenum type, GLsizei stride, const void* pointer);
    void glTexCoordPointer(GLint size, GLenum type, GLsizei stride, const void* pointer);
    void glNormalPointer(GLenum type, GLsizei stride, const void* pointer);
    void glColorPointer(GLint size, GLenum type, GLsizei stride, const void* pointer);
    void glDrawArrays(GLenum mode, GLint first, GLsizei count);
    void glDrawElements(GLenum mode, GLsizei count, GLenum type, const void* indices);
    void glEnableClientState(GLenum array);
    void glDisableClientState(GLenum array);


    void glTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
    void glPixelStorei(GLenum pname, GLint param);
    void glGenTextures(GLsizei n, GLuint *textures);
    void glDeleteTextures(GLsizei n, const GLuint * textures);
    void glBindTexture(GLenum target, GLuint texture);
    void glTexParameteri(GLenum target, GLenum pname, GLint param);
    void glTexEnvi(GLenum target, GLenum pname, GLint param);
    void glTexEnvf(GLenum target, GLenum pname, GLfloat param);
    void glTexEnvfv(GLenum target, GLenum pname, const GLfloat* param);

    void glMaterialf(GLenum face, GLenum pname, GLfloat param);
    void glMaterialfv(GLenum face, GLenum pname, const GLfloat* params);
    void glLightf(GLenum light, GLenum pname, GLfloat param);
    void glLightfv(GLenum light, GLenum pname, const GLfloat* params);
    void glLightModelf(GLenum pname, GLfloat param);
    void glLightModelfv(GLenum pname, const GLfloat* params);

    void glClear(GLbitfield mask);
    void glClearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
    void glClearDepthf(GLclampf depth);
    void glClearStencil(GLint s);
    void glColorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);

    void glDepthMask(GLboolean flag);
    void glDepthFunc(GLenum func);
    void glAlphaFunc(GLenum func, GLclampf ref);

    void glBlendFunc(GLenum sfactor, GLenum dfactor);
    void glLogicOp(GLenum opcode);

    void glPushMatrix();
    void glPopMatrix();

    void glCullFace(GLenum mode);

    void glEnable(GLenum cap);
    void glDisable(GLenum cap);

    const GLubyte* glGetString(GLenum name);
    void glGetIntegerv(GLenum pname, GLint* params);
    void glGetFloatv(GLenum pname, GLfloat* params);
    void glGetBooleanv(GLenum pname, GLboolean* params);

    void gluPerspective(GLfloat fovy, GLfloat aspect, GLfloat zNear, GLfloat zFar);
    void gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez, GLfloat centerx,
                   GLfloat centery, GLfloat centerz, GLfloat upx, GLfloat upy,
                   GLfloat upz);

    void commit();

private:
    struct Texture
    {
        bool inUse;
        uint16_t* gramAddr;
        GLenum internalFormat;
        GLsizei width;
        GLsizei height;
    };

    static constexpr uint8_t MODEL_MATRIX_STACK_DEPTH = 16;
    static constexpr uint8_t PROJECTION_MATRIX_STACK_DEPTH = 4;


    void setClientState(const GLenum array, bool enable);
    // It would be nice to have std::optional, but it does not work with arduino
    // If we have this, we could make all this functions const and return an empty optional if the conversion failed
    IRenderer::BlendFunc convertGlBlendFuncToRenderBlendFunc(const GLenum blendFunc);
    TnL::RenderObj::Type convertType(GLenum type);
    TnL::RenderObj::DrawMode convertDrawMode(GLenum drawMode);
    IRenderer::TextureWrapMode convertGlTextureWrapMode(const GLenum mode);
    void recalculateAndSetTnLMatrices();
    static Vec4 calcTexGenEyePlane(const Mat44& mat, const Vec4& plane);

    IRenderer& m_renderer;
    TnL m_tnl;
    TnL::RenderObj m_renderObj;

    // Buffer
    std::vector<Vec4> m_vertexBuffer;
    std::vector<Vec2> m_textureVertexBuffer;
    std::vector<Vec3> m_normalVertexBuffer;
    std::vector<Vec4i> m_colorVertexBuffer;

    // State values
    Vec4i m_vertexColor;
    Vec2 m_textureCoord;
    Vec3 m_normal;
    GLenum m_beginMode = GL_TRIANGLES;

    // OpenGL Context Variables
    // Matrix modes
    GLenum matrixMode = GL_PROJECTION;
    Mat44 m_mStack[MODEL_MATRIX_STACK_DEPTH];
    Mat44 m_pStack[PROJECTION_MATRIX_STACK_DEPTH];
    uint8_t m_mStackIndex{0};
    uint8_t m_pStackIndex{0};
    Mat44 m_m; // Model matrix
    Mat44 m_p; // Projection matrix
    Mat44 m_t;
    bool m_matricesOutdated{true}; // Marks when the model and projection matrices have changed so that the transformation and normal matrices have to be recalculated

    // Textures
    GLint m_unpackAlignment = 4;
    GLuint m_boundTexture = 0;
    bool m_enableTextureMapping = true;
    GLint m_texEnvParam = GL_REPLACE;

    // Test functions
    bool m_enableAlphaTest = true;
    GLclampf m_alphaTestRefValue = 0.0f;
    GLenum m_alphaTestFunc = GL_ALWAYS;

    // Blending
    bool m_enableBlending = true;
    GLenum m_blendDfactor = GL_ZERO;
    GLenum m_blendSfactor = GL_ONE;

    // Cull mode
    bool m_enableCulling = false;
    GLenum m_cullMode = GL_BACK;
    
    // Texture memory allocator
    std::array<Texture, 64> m_textures;

    GLint m_error = GL_NO_ERROR;
};

inline GLenum operator- (const GLenum lhs, const GLenum rhs)
{
    return static_cast<GLenum>(static_cast<const int32_t>(lhs) - static_cast<const int32_t>(rhs));
}

#endif // ICEGL_HPP
