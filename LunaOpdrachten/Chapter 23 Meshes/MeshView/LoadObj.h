#ifndef LOADObj_H
#define LOADObj_H

#include "MeshGeometry.h"
#include "LightHelper.h"
#include "Vertex.h"

struct ObjMaterial
{
	Material Mat;
	bool AlphaClip;
	std::string EffectTypeName;
	std::wstring DiffuseMapName;
	std::wstring NormalMapName;
};

class ObjLoader
{
public:
	bool LoadObj(const std::string& filename,
		std::vector<Vertex::PosNormalTexTan>& vertices,
		std::vector<USHORT>& indices,
		std::vector<MeshGeometry::Subset>& subsets,
		std::vector<ObjMaterial>& mats);

private:
	void ReadMaterials(std::ifstream& fin, UINT numMaterials, std::vector<ObjMaterial>& mats);
	void ReadSubsetTable(std::ifstream& fin, UINT numSubsets, std::vector<MeshGeometry::Subset>& subsets);
	void ReadVertices(std::ifstream& fin, UINT numVertices, std::vector<Vertex::PosNormalTexTan>& vertices);
	void ReadTriangles(std::ifstream& fin, UINT numTriangles, std::vector<USHORT>& indices);
};

#endif // LOADObj_H