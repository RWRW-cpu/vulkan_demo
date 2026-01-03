# CodeZipper Summary

**Source:** D:\code\w_cplus\nanite\dist\back
**Created:** 2026-01-03T21:08:02.964931
**Files:** 16
**Total Size:** 69434 bytes

<!-- CODEZIPPER_CONTENT_START -->

## File: App.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 11560 bytes

```
import * as THREE from "three";

import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";

import { BetterStats, Stat } from "./BetterStats";

import { OBJLoaderIndexed } from "./OBJLoaderIndexed";
import { MeshletMerger } from "./MeshletMerger";

import { MeshletSimplifier_wasm } from "./utils/MeshletSimplifier";
import { MeshletCleaner } from "./utils/MeshletCleaner";
import { BoundingVolume, Meshlet } from "./Meshlet";
import { MeshletCreator } from "./utils/MeshletCreator";
import { MeshletGrouper } from "./MeshletGrouper";
import { MeshSimplifyScale } from "./utils/MeshSimplifyScale";


import Stats from "three/examples/jsm/libs/stats.module.js";

import { MeshletObject3D } from "./MeshletObject3D";


export class App {
    private canvas: HTMLCanvasElement;

    private renderer: THREE.WebGLRenderer;
    private scene: THREE.Scene;
    private camera: THREE.PerspectiveCamera;
    private controls: OrbitControls;

    private stats: BetterStats;

    private statsT: Stats;

    private lodStat: Stat;

    constructor(canvas: HTMLCanvasElement) {
        this.canvas = canvas;

        this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas, antialias: true });
        this.scene = new THREE.Scene();
        this.camera = new THREE.PerspectiveCamera(32, this.canvas.width / this.canvas.height, 0.01, 10000);
        this.camera.position.z = 1;

        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        this.controls.target.set(0, 0.1, 0);
        // this.controls keyBoard true
        this.controls.position0.set(-1.2651965602997748, 2.6593300144656036, -1.299294430426245);
        this.controls.update();

        this.stats = new BetterStats(this.renderer);
        document.body.appendChild(this.stats.domElement);

        this.statsT = new Stats();
        document.body.appendChild(this.statsT.dom);

        this.lodStat = new Stat("TestLOD", `0ms`);
        this.stats.addStat(this.lodStat);

        // DEBUG
        window.renderer = this.renderer
        window.scene = this.scene;
        window.camera = this.camera;

        this.render();
    }

    // Helpers
    private static rand(co: number) {
        function fract(n) {
            return n % 1;
        }

        return fract(Math.sin((co + 1) * 12.9898) * 43758.5453);
    }

    private createSphere(radius, color, position: number[]) {
        let g = new THREE.SphereGeometry(radius);

        const m = new THREE.MeshBasicMaterial({
            wireframe: true,
            side: 0,
            color: color,
        });
        const mesh = new THREE.Mesh(g, m);
        mesh.position.set(position[0], position[1], position[2]);

        this.scene.add(mesh);
    }

    private createMesh(vertices: ArrayLike<number>, indices: ArrayLike<number>, params: { color?: number, position?: number[], opacity?: number, scale?: number[] }, DEBUG: boolean = false): THREE.Mesh {
        // if (DEBUG === false) return;

        let g = new THREE.BufferGeometry();
        g.setAttribute("position", new THREE.Float32BufferAttribute(vertices, 3));
        g.setIndex(new THREE.Uint16BufferAttribute(indices, 1));

        const m = new THREE.MeshBasicMaterial({
            wireframe: false,
            color: params.color ? params.color : 0xffffff,
            transparent: params.opacity ? true : false,
            opacity: params.opacity ? params.opacity : 0.0
        });
        const mesh = new THREE.Mesh(g, m);
        if (params.position) {
            mesh.position.set(params.position[0], params.position[1], params.position[2]);
        }
        if (params.scale) {
            mesh.scale.set(params.scale[0], params.scale[1], params.scale[2]);
        }
        this.scene.add(mesh);

        return mesh;
    }

    private showMeshlets(meshlets: Meshlet[], position: number[], scale?: number[], color?: number): THREE.Mesh[] {
        let meshes: THREE.Mesh[] = [];
        for (let i = 0; i < meshlets.length; i++) {
            const meshlet_color = color ? color : App.rand(i) * 0xffffff;
            const mesh = this.createMesh(meshlets[i].vertices_raw, meshlets[i].indices_raw, { color: meshlet_color, position: position, scale: scale });
            meshes.push(mesh);
        }
        return meshes;
    }


    public async processObj(objURL: string) {
        OBJLoaderIndexed.load(objURL, async (objMesh) => {
            const objVertices = objMesh.vertices;
            const objIndices = objMesh.indices;

            // Original mesh
            const xO = 0.3;
            const yO = -0.3;
            const DEBUG = false;
            // const originalMesh = this.createMesh(objVertices, objIndices, { opacity: 0.2, position: [-0.3, 0, 0] });

            async function appendMeshlets(simplifiedGroup: Meshlet, bounds: BoundingVolume, error: number): Promise<Meshlet[]> {
                const split = await MeshletCreator.build(simplifiedGroup.vertices_raw, simplifiedGroup.indices_raw, 255, 128);
                for (let s of split) {
                    s.clusterError = error;
                    s.boundingVolume = bounds;
                }
                return split;
            }

            let previousMeshlets: Map<number, Meshlet> = new Map();

            const calculateChildrenError = (group: Meshlet[]): number => {
                let childrenError = 0.0;
                for (let m of group) {
                    const previousMeshlet = previousMeshlets.get(m.id);
                    if (!previousMeshlet) throw new Error("Could not find previous meshlet");
                    childrenError = Math.max(childrenError, previousMeshlet.clusterError);
                }
                return childrenError;
            };

            const updateParentErrors = (group: Meshlet[], meshSpaceError: number, boundingVolume: BoundingVolume): void => {
                for (let m of group) {
                    const previousMeshlet = previousMeshlets.get(m.id);
                    if (!previousMeshlet) throw new Error("Could not find previous meshlet");
                    previousMeshlet.parentError = meshSpaceError;
                    previousMeshlet.parentBoundingVolume = boundingVolume;
                }
            };

            const updateMeshletRelationships = (group: Meshlet[], parent: Meshlet, lod: number): void => {
                for (let m of group) {
                    m.children.push(parent);
                    m.lod = lod;
                }
                parent.parents.push(...group);
            };

            const step = async (meshlets: Meshlet[], y: number, scale = [1, 1, 1], lod: number): Promise<Meshlet[]> => {
                if (previousMeshlets.size === 0) {
                    for (let m of meshlets) previousMeshlets.set(m.id, m);
                }



                let nparts = Math.ceil(meshlets.length / 4);
                let grouped = [meshlets];
                if (nparts > 1) {
                    grouped = await MeshletGrouper.group(meshlets, nparts);
                }







                let x = 0;
                let splitOutputs: Meshlet[] = [];
                for (let i = 0; i < grouped.length; i++) {
                    const group = grouped[i];
                    // merge
                    const mergedGroup = MeshletMerger.merge(group);
                    const cleanedMergedGroup = await MeshletCleaner.clean(mergedGroup);

                    // simplify
                    const simplified = await MeshletSimplifier_wasm.simplify(cleanedMergedGroup, cleanedMergedGroup.indices_raw.length / 2);

                    const localScale = await MeshSimplifyScale.scaleError(simplified.meshlet);
                    // console.log(localScale, simplified.result_error)

                    const meshSpaceError = simplified.result_error * localScale + calculateChildrenError(group);

                    updateParentErrors(group, meshSpaceError, simplified.meshlet.boundingVolume);

                    const out = await appendMeshlets(simplified.meshlet, simplified.meshlet.boundingVolume, meshSpaceError);


                    for (let o of out) {
                        previousMeshlets.set(o.id, o);
                        splitOutputs.push(o);
                    }


                    updateMeshletRelationships(group, out[0], lod);


                    if (DEBUG) {
                        this.showMeshlets(group, [x + (xO * 1), y, 0], [1, 1, 1], App.rand(i) * 0xffffff);
                        this.showMeshlets([cleanedMergedGroup], [x + (xO * 2), y, 0], [1, 1, 1], App.rand(i) * 0xffffff);
                        this.showMeshlets([simplified.meshlet], [+ (xO * 3), y, 0], [1, 1, 1], App.rand(i) * 0xffffff);
                    }
                }

                if (DEBUG) {
                    this.showMeshlets(meshlets, [0.0, y, 0], scale);
                    this.showMeshlets(splitOutputs, [+ (xO * 4), y, 0], [1, 1, 1]);
                }

                return splitOutputs;
            }
            const meshlets = await MeshletCreator.build(objVertices, objIndices, 255, 128);
            console.log(meshlets)

            let rootMeshlet: Meshlet;

            const maxLOD = 100;
            let y = 0.0;
            let inputs = meshlets;

            for (let lod = 0; lod < maxLOD; lod++) {
                const outputs = await step(inputs, y, [1, 1, 1], lod);

                console.log("inputs", inputs.map(m => m.indices_raw.length / 3));
                console.log("outputs", outputs.map(m => m.indices_raw.length / 3));

                if (outputs.length === 1) {
                    console.log("WE are done at lod", lod)

                    rootMeshlet = outputs[0];
                    rootMeshlet.lod = lod + 1;
                    rootMeshlet.parentBoundingVolume = rootMeshlet.boundingVolume;

                    break;
                }

                inputs = outputs;
                y += yO;
                console.log("\n");
            }

            console.log("root", rootMeshlet);


            if (rootMeshlet === null) throw Error("Root meshlet is invalid!");

















            function traverse(meshlet: Meshlet, fn: (meshlet: Meshlet) => void, visited: number[] = []) {
                if (visited.indexOf(meshlet.id) !== -1) return;

                fn(meshlet);
                visited.push(meshlet.id);

                for (let child of meshlet.parents) {
                    traverse(child, fn, visited);
                }
            }

            const allMeshlets: Meshlet[] = [];
            traverse(rootMeshlet, m => allMeshlets.push(m));
            console.log("total meshlets", allMeshlets.length);

            const m = new MeshletObject3D(allMeshlets, this.lodStat);
            this.scene.add(m.mesh);



            
            for (let x = 0; x < 200; x++) {
                for (let y = 0; y < 30; y++) {
                    m.addMeshletAtPosition(new THREE.Vector3(x, 0, y));
                }
            }
        })
    }

    private render() {

        this.stats.update();
        this.statsT.update();

        this.renderer.render(this.scene, this.camera);

        requestAnimationFrame(() => { this.render() });
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: BetterStats.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 3789 bytes

```
import { WebGLRenderer } from "three";

export class Stat {
    public rowElement: HTMLTableRowElement;
    private nameEntry: HTMLTableCellElement;
    private valueEntry: HTMLTableCellElement;

    public set value(value: string) {
        this.valueEntry.textContent = value;
    }

    constructor(name: string, defaultValue: string) {
        this.rowElement = document.createElement("tr");
        this.nameEntry = document.createElement("td");
        this.valueEntry = document.createElement("td");
        this.nameEntry.textContent = name;
        this.valueEntry.textContent = defaultValue;

        this.rowElement.append(this.nameEntry, this.valueEntry);
    }
}

export class BetterStats {
    private renderer: WebGLRenderer;
    private readonly domElement: HTMLTableElement;

    private stats: Stat[];

    // Internal stats
    private programsStat: Stat;
    private geometriesStat: Stat;
    private texturesStat: Stat;

    private callsStat: Stat;
    private fpsStat: Stat;
    private trianglesStat: Stat;
    private pointsStat: Stat;
    private linesStat: Stat;

    private lastTime: number;
    private fps: number;

    constructor(webglRenderer: WebGLRenderer) {
        this.renderer = webglRenderer;
        this.domElement = document.createElement("table");
        this.domElement.style.backgroundColor = "#222222";
        this.domElement.style.color = "white";
        this.domElement.style.fontSize = "9px";
        this.domElement.style.fontFamily = "monospace";
        this.domElement.style.position = "absolute";
        this.domElement.style.top = "5px";
        this.domElement.style.right = "5px";
        this.domElement.style.right = "5px";
        this.domElement.style.borderRadius = "5px";
        this.domElement.style.border = "1px solid";

        this.stats = [];
        this.lastTime = 0;
        this.fps = 0;

        this.programsStat = new Stat("Programs", "0");
        this.geometriesStat = new Stat("Geometries", "0");
        this.texturesStat = new Stat("Textures", "0");

        this.callsStat = new Stat("Calls", "0");
        this.fpsStat = new Stat("FPS", "0");
        this.trianglesStat = new Stat("Triangles", "0");
        this.pointsStat = new Stat("Points", "0");
        this.linesStat = new Stat("Lines", "0");

        this.addStat(this.programsStat);
        this.addStat(this.geometriesStat);
        this.addStat(this.texturesStat);
        this.addStat(this.callsStat);
        this.addStat(this.fpsStat);
        this.addStat(this.trianglesStat);
        this.addStat(this.pointsStat);
        this.addStat(this.linesStat);
    }

    public addStat(stat: Stat) {
        if (this.stats.indexOf(stat) !== -1) return;

        this.domElement.append(stat.rowElement);
    }

    public update() {
        const currentTime = performance.now();
        const elapsed = currentTime - this.lastTime;
        this.lastTime = currentTime;
        const currentFPS = Math.floor(1 / elapsed * 1000);

        const alpha = 0.1;
        this.fps = (1 - alpha) * this.fps + alpha * currentFPS;

        this.programsStat.value = this.renderer.info.programs.length.toString();
        this.geometriesStat.value = this.renderer.info.memory.geometries.toString();
        this.texturesStat.value = this.renderer.info.memory.textures.toString();
        this.callsStat.value = this.renderer.info.render.calls.toString();
        this.fpsStat.value = this.fps.toFixed(0);
        this.trianglesStat.value = this.renderer.info.render.triangles.toString();
        this.pointsStat.value = this.renderer.info.render.points.toString();
        this.linesStat.value = this.renderer.info.render.lines.toString();
    }
};
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: DiagramVisualizer.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 5587 bytes

```
interface Node {
    id: string;
    lod: string;
    data: any;
}

export class DAG {
    public nodes: { [key: string]: Node };
    public parentToChild: { [key: string]: string[] };
    public childToParent: { [key: string]: string[] };
    public lodToNode: { [key: string]: string[] };

    constructor() {
        this.nodes = {};
        this.parentToChild = {};
        this.childToParent = {};
        this.lodToNode = {};
    }

    private addRelationship(map: { [key: string]: string[] }, queryKey: string, from: string, to: string) {
        let mapArray = map[queryKey] ? map[queryKey] : [];
        if (mapArray.indexOf(to) === -1) mapArray.push(to);
        map[queryKey] = mapArray;
    }

    private addNode(node: Node) {
        if (!this.nodes[node.id]) this.nodes[node.id] = node;
    }

    public add(parent: Node, child: Node) {
        this.addNode(parent);
        this.addNode(child);

        this.addRelationship(this.parentToChild, parent.id, parent.id, child.id);
        this.addRelationship(this.childToParent, child.id, child.id, parent.id);

        this.addRelationship(this.lodToNode, parent.lod, parent.id, parent.id);
        this.addRelationship(this.lodToNode, child.lod, child.id, child.id);
    }

    public toDot() {
        let dotviz = `digraph G {\n`;
        for (let child in this.childToParent) {
            for (let parentNode of this.childToParent[child]) {
                dotviz += `\t"${parentNode}\n${this.nodes[parentNode].lod}" -> "${child}\n${this.nodes[child].lod}"\n`
            }
        }
        dotviz += "}";
        return dotviz;
    }
}


interface Point {
    x: number;
    y: number;
}

export class DiagramVisualizer {
    private canvas: HTMLCanvasElement;
    private context: CanvasRenderingContext2D;

    private dag: DAG;

    private nodeStatus: {[key: string]: boolean};

    constructor(width: number, height: number) {
        this.canvas = document.createElement("canvas");
        this.canvas.width = width * window.devicePixelRatio // Hack for HDPI
        this.canvas.height = height * window.devicePixelRatio; // Hack for HDPI
        this.canvas.style.position = "absolute";
        this.canvas.style.top = "5px";
        this.canvas.style.left = "5px";
        this.canvas.style.backgroundColor = "#222222";
        this.canvas.style.border = "1px solid #ffffff";
        this.canvas.style.borderRadius = "5px";
        this.canvas.style.zoom = (1/window.devicePixelRatio).toString(); // Hack for HDPI
        this.context = this.canvas.getContext("2d") as CanvasRenderingContext2D;
        document.body.appendChild(this.canvas);

        this.nodeStatus = {}
        this.dag = new DAG();
    }

    public add(parent: Node, child: Node) {
        this.dag.add(parent, child);
        this.nodeStatus[parent.id] = false;
        this.nodeStatus[child.id] = false;
    }

    public setNodeStatus(nodeId: string, enabled: boolean) {
        if (this.nodeStatus[nodeId] === undefined) {
            console.warn("Could not find node, need to add it first");
            return;
        }
        this.nodeStatus[nodeId] = enabled;
    }

    private drawLine(from: Point, to: Point, color: string) {
        this.context.strokeStyle = color;
        this.context.beginPath();
        this.context.moveTo(from.x, from.y);
        this.context.lineTo(to.x, to.y);
        this.context.closePath();
        this.context.stroke();
    }

    private drawCircle(position: Point, radius: number, color: string) {
        this.context.fillStyle = color;
        this.context.beginPath();
        this.context.arc(position.x, position.y, radius, 0, 180 / Math.PI);
        this.context.closePath();
        this.context.fill();
    }

    public render() {
        this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);

        function sortByLOD(dag: DAG) {
            let lodNodesArray: string[][] = [];
            for (let l in dag.lodToNode) lodNodesArray[l] = dag.lodToNode[l];
            return lodNodesArray.sort();
        }

        const sortedLods = sortByLOD(this.dag);
        const sortedLODKeys = Object.keys(sortedLods).reverse();

        const nodePositions: Map<string, {x: number, y: number}> = new Map();
        
        const yStep = this.canvas.height / sortedLODKeys.length;
        let y = yStep * 0.5;
        for (let l = 0; l < sortedLODKeys.length; l++) {
            const lod = sortedLODKeys[l];
            const nodes = this.dag.lodToNode[lod];

            // Draw lods
            this.drawLine({x: 0, y: y + yStep * 0.5}, {x: this.canvas.width, y: y + yStep * 0.5}, "#ffffff20");

            let x = this.canvas.width * 0.5 / nodes.length;
            for (let i = 0; i < nodes.length; i++) {
                const pos = {x: x, y: y};
                x += this.canvas.width / nodes.length;

                nodePositions.set(nodes[i], pos);
            }
            y += yStep;

        }

        // Make connections
        for (let p in this.dag.parentToChild) {
            const ppos = nodePositions.get(p);
            for (let c of this.dag.parentToChild[p]) {
                const cpos = nodePositions.get(c);
                this.drawLine(ppos, cpos, "gray")
            }
        }

        for (let [id, position] of nodePositions) {
            const color = this.nodeStatus[id] ? "green" : "white";
            this.drawCircle(position, 3, color);
        }
    }

}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: index.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 26 bytes

```
export {App} from "./App";
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: Meshlet.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 7483 bytes

```
function hash(co: number) {
    function fract(n) {
        return n % 1;
    }

    return fract(Math.sin((co + 1) * 12.9898) * 43758.5453);
}

let seed = 0;
export function seedRandom() {
    return Math.abs(hash(seed += 1));
}

export class Vertex {
    public x: number;
    public y: number;
    public z: number;

    constructor(x: number, y: number, z: number) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public static dot(a: Vertex, b: Vertex): number {
		return a.x * b.x + a.y * b.y + a.z * b.z;
	}

    public static applyMatrix4(a: Vertex, m: number[]): Vertex {
		const x = a.x, y = a.y, z = a.z;
		const e = m;

		const w = 1 / ( e[ 3 ] * x + e[ 7 ] * y + e[ 11 ] * z + e[ 15 ] );

		let x1 = ( e[ 0 ] * x + e[ 4 ] * y + e[ 8 ] * z + e[ 12 ] ) * w;
		let y1 = ( e[ 1 ] * x + e[ 5 ] * y + e[ 9 ] * z + e[ 13 ] ) * w;
		let z1 = ( e[ 2 ] * x + e[ 6 ] * y + e[ 10 ] * z + e[ 14 ] ) * w;

		return new Vertex(x1, y1, z1);
	}

    public hash(): string {
        return `${this.x.toFixed(5)},${this.y.toFixed(5)},${this.z.toFixed(5)}`;
    }
};

export class Triangle {
    public a: number;
    public b: number;
    public c: number;

    constructor(a: number, b: number, c: number) {
        this.a = a;
        this.b = b;
        this.c = c;
    }
}

export interface BoundingVolume {
    AABB: {min: Vertex, max: Vertex};
    center: Vertex;
    radius: number;
} 

export class Edge {
    public fromIndex: number;
    public toIndex: number;

    constructor(fromIndex: number, toIndex: number) {
        this.fromIndex = fromIndex;
        this.toIndex = toIndex;
    }

    public equal(other: Edge): boolean {
        return this.fromIndex === other.fromIndex && this.toIndex === other.toIndex;
    }

    public isAdjacent(other: Edge): boolean {
        return this.fromIndex === other.fromIndex ||
            this.fromIndex === other.toIndex ||
            this.toIndex === other.fromIndex ||
            this.toIndex === other.toIndex;
    }
};

export class Meshlet {
    public vertices_raw: Float32Array;
    public indices_raw: Uint32Array;

    public vertices: Vertex[];
    public triangles: Triangle[];
    public edges: Edge[];

    public boundaryEdges: Edge[];

    public id: number;

    public lod: number;
    public children: Meshlet[];
    public parents: Meshlet[];


    public boundingVolume: BoundingVolume;
    // public parentBoundingVolume: BoundingVolume;
    public parentError: number = Infinity;
    public clusterError: number = 0;

    constructor(vertices: Float32Array, indices: Uint32Array) {
        this.vertices_raw = vertices;
        this.indices_raw = indices;

        this.vertices = this.buildVertexMap(vertices);
        this.triangles = this.buildTriangleMap(indices);
        this.edges = this.buildEdgeMap(this.triangles);
        this.boundaryEdges = this.getBoundary(this.edges);

        this.id = Math.floor(seedRandom() * 10000000);

        this.boundingVolume = this.computeBoundingSphere(this.vertices);
        
        this.lod = 0;
        this.children = [];
        this.parents = [];
    }

    private buildVertexMap(vertices: Float32Array): Vertex[] {
        let vertex: Vertex[] = [];
        for (let i = 0; i < vertices.length; i += 3) {
            vertex.push(new Vertex(vertices[i + 0], vertices[i + 1], vertices[i + 2]));
        }
        return vertex;
    }

    private buildTriangleMap(indices: Uint32Array): Triangle[] {
        let triangles: Triangle[] = [];
        for (let i = 0; i < indices.length; i += 3) {
            triangles.push(new Triangle(indices[i + 0], indices[i + 1], indices[i + 2]));
        }
        return triangles;
    }

    private buildEdgeMap(triangles: Triangle[]): Edge[] {
        let edges: Edge[] = [];
        for (let i = 0; i < triangles.length; i++) {
            const triangle = triangles[i];

            const face = [triangle.a, triangle.b, triangle.c];

            for (let i = 0; i < 3; i++) {
                const startIndex = face[i];
                const endIndex = face[(i + 1) % 3];

                edges.push(new Edge(
                    Math.min(startIndex, endIndex),
                    Math.max(startIndex, endIndex)
                ))
            }
        }
        return edges;
    }

    private getBoundary(edges: Edge[]): Edge[] {
        let counts = new Array(edges.length).fill(0);

        for (let i = 0; i < edges.length; i++) {

            const a = edges[i];
            for (let j = 0; j < edges.length; j++) {
                const b = edges[j];

                if (a.fromIndex === b.fromIndex && a.toIndex === b.toIndex) {
                    counts[i]++;
                }
            }
        }

        let boundaryEdges: Edge[] = [];
        for (let i = 0; i < counts.length; i++) {
            if (counts[i] == 1) {
                boundaryEdges.push(edges[i]);
            }
        }
        return boundaryEdges;
    }

    public getEdgeVertices(edge: Edge): Vertex[] {
        const from = edge.fromIndex;
        const to = edge.toIndex;
        return [this.vertices[from], this.vertices[to]];
    }

    // TODO: Clean this
    public getEdgeHash(edge: Edge): string {
        function hashVertex(vertex: Vertex): string {
            // const xh = hash(vertex.x + 11.1212);
            // const yh = hash(vertex.y + 23.5412);
            // const zh = hash(vertex.z + 34.7732);

            // const vertexHash = xh + yh + zh;
            // return Math.abs(Math.round(vertexHash * 1000000));

            // const xh = `${vertex.x}`;
            // const yh = `${vertex.x}`;
            // const zh = `${vertex.x}`;
            return `${vertex.x},${vertex.y},${vertex.z}`;
        }

        const edgeVertices = this.getEdgeVertices(edge);

        const fromVertexHash = hashVertex(edgeVertices[0]);
        const toVertexHash = hashVertex(edgeVertices[1]);
        // const edgeHash = fromVertexHash + toVertexHash;
        const edgeHash = `${fromVertexHash}:${toVertexHash}`;
        return edgeHash;
    }

    private computeBoundingSphere(vertices: Vertex[]) {
        let maxX = -Infinity; let maxY = -Infinity; let maxZ = -Infinity;
        let minX = Infinity; let minY = Infinity; let minZ = Infinity;

        for (let vertex of vertices) {
            if (vertex.x > maxX) maxX = vertex.x;
            if (vertex.x < minX) minX = vertex.x;
            
            if (vertex.y > maxY) maxY = vertex.y;
            if (vertex.y < minY) minY = vertex.y;

            if (vertex.z > maxZ) maxZ = vertex.z;
            if (vertex.z < minZ) minZ = vertex.z;

        }
    
        return {
            AABB: {
                min: new Vertex(minX, minY, minZ),
                max: new Vertex(maxX, maxY, maxZ),
            },
            center: new Vertex(minX + (maxX-minX)/2, minY + (maxY-minY)/2, minZ + (maxZ-minZ)/2),
            radius: Math.max((maxX-minX)/2,(maxY-minY)/2,(maxZ-minZ)/2)
        }
    }

    public clone(): Meshlet {
        return new Meshlet(this.vertices_raw, this.indices_raw);
    }

    public getGroupMeshlets(): Meshlet[] {
        if (this.parents.length === 0) return [];

        const parent = this.parents[0];
        return parent.children;
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: MeshletGrouper.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 2617 bytes

```
import { METISWrapper } from "./METISWrapper";
import { Meshlet } from "./Meshlet"

export class MeshletGrouper {
    
    public static adjacencyList(meshlets: Meshlet[]): number[][] {

        let vertexHashToMeshletMap: Map<string, number[]> = new Map();

        for (let i = 0; i < meshlets.length; i++) {
            const meshlet = meshlets[i];
            for (let j = 0; j < meshlet.boundaryEdges.length; j++) {
                const boundaryEdge = meshlet.boundaryEdges[j];
                const edgeHash = meshlet.getEdgeHash(boundaryEdge);

                let meshletList = vertexHashToMeshletMap.get(edgeHash);
                if (!meshletList) meshletList = [];

                meshletList.push(i);
                vertexHashToMeshletMap.set(edgeHash, meshletList);
            }
        }
        const adjacencyList: Map<number, Set<number>> = new Map();

        for (let [_, indices] of vertexHashToMeshletMap) {
            if (indices.length === 1) continue;

            for (let index of indices) {
                if (!adjacencyList.has(index)) {
                    adjacencyList.set(index, new Set());
                }
                for (let otherIndex of indices) {
                    if (otherIndex !== index) {
                        adjacencyList.get(index).add(otherIndex);
                    }
                }
            }
        }


        let adjacencyListArray: number[][] = [];
        // Finally, to array
        for (let [key, adjacents] of adjacencyList) {
            if (!adjacencyListArray[key]) adjacencyListArray[key] = [];

            adjacencyListArray[key].push(...Array.from(adjacents));
        }
        return adjacencyListArray;
    }

    public static rebuildMeshletsFromGroupIndices(meshlets: Meshlet[], groups: number[][]): Meshlet[][] {
        let groupedMeshlets: Meshlet[][] = [];

        for (let i = 0; i < groups.length; i++) {
            if (!groupedMeshlets[i]) groupedMeshlets[i] = [];
            for (let j = 0; j < groups[i].length; j++) {
                const meshletId = groups[i][j];
                const meshlet = meshlets[meshletId];
                groupedMeshlets[i].push(meshlet);
            }
        }
        return groupedMeshlets;
    }

    public static async group(meshlets: Meshlet[], nparts: number): Promise<Meshlet[][]> {
        const adj = MeshletGrouper.adjacencyList(meshlets);

        const groups = await METISWrapper.partition(adj, nparts);
        return MeshletGrouper.rebuildMeshletsFromGroupIndices(meshlets, groups);
    }

}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: MeshletMerger.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 950 bytes

```
import { Meshlet } from "./Meshlet";

// From: THREE.js
export class MeshletMerger {
    public static merge(meshlets: Meshlet[]): Meshlet {
        const vertices: number[] = [];
        const indices: number[] = [];
    
        // merge indices
        let indexOffset = 0;
        const mergedIndices: number[] = [];
    
        for (let i = 0; i < meshlets.length; ++i) {
            const indices = meshlets[i].indices_raw;
    
            for (let j = 0; j < indices.length; j++) {
                mergedIndices.push(indices[j] + indexOffset);
            }
            indexOffset += meshlets[i].vertices.length;
        }
    
        indices.push(...mergedIndices);
    
        // merge attributes
        for (let i = 0; i < meshlets.length; ++i) {
            vertices.push(...meshlets[i].vertices_raw);
        }
    
        const merged = new Meshlet(vertices, indices);
        return merged;
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: MeshletObject3D.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 12060 bytes

```
import { Stat } from "./BetterStats";
import { Meshlet, Vertex } from "./Meshlet";

import * as THREE from "three";

interface ProcessedMeshlet {
    meshletId: number;
    vertexOffset: number;
    vertexCount: number;
}

interface NonIndexedMeshlet {
    meshlet: Meshlet;
    vertices: Float32Array;
}

export class MeshletObject3D {
    private static VERTICES_TEXTURE_SIZE = 1024;

    private meshlets: Meshlet[];

    private meshletsProcessed: Map<Meshlet, ProcessedMeshlet>;
    
    private instancedGeometry: THREE.InstancedBufferGeometry;
    private indicesAttribute: THREE.Uint16BufferAttribute;
    private localPositionAttribute: THREE.Float32BufferAttribute;

    public readonly mesh: THREE.Mesh;

    
    private rootMeshlet: Meshlet;
    private meshletMatrices: THREE.Matrix4[];

    private lodStat: Stat;
    private tempMatrix: THREE.Matrix4;

    constructor(meshlets: Meshlet[], stat: Stat) {
        this.meshlets = meshlets;
        this.meshletMatrices = [];
        this.lodStat = stat;
        this.tempMatrix = new THREE.Matrix4();

        // Get root meshlet
        let meshletsPerLOD: Meshlet[][] = [];

        for (let meshlet of this.meshlets) {
            if (!meshletsPerLOD[meshlet.lod]) meshletsPerLOD[meshlet.lod] = [];

            meshletsPerLOD[meshlet.lod].push(meshlet);
        }
        
        for (let meshlets of meshletsPerLOD) {
            if (meshlets.length === 1) {
                this.rootMeshlet = meshlets[0];
                break;
            }
        }


        let nonIndexedMeshlets: NonIndexedMeshlet[] = [];
        for (let meshlet of this.meshlets) {
            nonIndexedMeshlets.push(this.meshletToNonIndexedVertices(meshlet));
        }

        this.meshletsProcessed = new Map();
        let currentVertexOffset = 0;
        for (let nonIndexedMeshlet of nonIndexedMeshlets) {
            this.meshletsProcessed.set(nonIndexedMeshlet.meshlet, {
                meshletId: nonIndexedMeshlet.meshlet.id,
                vertexOffset: currentVertexOffset, 
                vertexCount: nonIndexedMeshlet.vertices.length
            });
            currentVertexOffset += nonIndexedMeshlet.vertices.length;
        }

        const vertexTexture = this.createVerticesTexture(nonIndexedMeshlets);

        this.instancedGeometry = new THREE.InstancedBufferGeometry();
        this.instancedGeometry.instanceCount = 0;

        const positionAttribute = new THREE.InstancedBufferAttribute(new Float32Array(1152), 3);
        this.instancedGeometry.setAttribute('position', positionAttribute);

        this.localPositionAttribute = new THREE.InstancedBufferAttribute(new Float32Array(meshlets.length * 3), 3);
        this.instancedGeometry.setAttribute('localPosition', this.localPositionAttribute);
        this.localPositionAttribute.usage = THREE.StaticDrawUsage;

        this.indicesAttribute = new THREE.InstancedBufferAttribute(new Float32Array(meshlets.length), 1);
        this.instancedGeometry.setAttribute('index', this.indicesAttribute);
        this.indicesAttribute.usage = THREE.StaticDrawUsage;


        const material = new THREE.ShaderMaterial({
            vertexShader: `
                uniform sampler2D vertexTexture;
                uniform float verticesTextureSize;

                attribute vec3 localPosition;
                attribute float index;

                flat out int meshInstanceID;
                flat out int meshletInstanceID;
                flat out int vertexID;

                void main() {
                    float instanceID = float(gl_InstanceID);

                    float vid = mod(float(gl_VertexID), 384.0);
                    float i = float(index) + vid;
                    float x = mod(i, verticesTextureSize);
                    float y = floor(i / verticesTextureSize);
                    vec3 pos = texelFetch(vertexTexture, ivec2(x, y), 0).xyz;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos + localPosition, 1.0);

                    meshInstanceID = gl_InstanceID;
                    meshletInstanceID = int(index);
                    vertexID = int(vid);
                }
            `,
            fragmentShader: `
                flat in int meshletInstanceID;

                vec3 hashColor(int seed) {
                    uint x = uint(seed);
                    x = ((x >> 16u) ^ x) * 0x45d9f3bu;
                    x = ((x >> 16u) ^ x) * 0x45d9f3bu;
                    x = (x >> 16u) ^ x;
                    return vec3(
                        float((x & 0xFF0000u) >> 16u) / 255.0,
                        float((x & 0x00FF00u) >> 8u) / 255.0,
                        float(x & 0x0000FFu) / 255.0
                    );
                }

                void main() {
                    vec3 color = hashColor(meshletInstanceID);
                    gl_FragColor = vec4(color, 1.0);
                }
            `,
            uniforms: {
                vertexTexture: { value: vertexTexture },

                verticesTextureSize: {value: MeshletObject3D.VERTICES_TEXTURE_SIZE},
            },
            wireframe: false
        });

        this.mesh = new THREE.Mesh(this.instancedGeometry, material);
        this.mesh.frustumCulled = false;


        let renderer: THREE.WebGLRenderer | null = null;
        let camera: THREE.Camera | null = null;
        this.mesh.onBeforeRender = (renderer, scene, camera, geometry) => {
            const startTime = performance.now();
                
            this.render(renderer, camera);
            
            const elapsed = performance.now() - startTime;
            this.lodStat.value = `${elapsed.toFixed(3)}ms`;
        }
    }

    private projectErrorToScreen(center: Vertex, radius: number, screenHeight: number): number {
        if (radius === Infinity) return radius;

        const testFOV = Math.PI * 0.5;
        const cotHalfFov = 1.0 / Math.tan(testFOV / 2.0);
        const d2 = Vertex.dot(center, center);
        const r = radius;
        return screenHeight / 2.0 * cotHalfFov * r / Math.sqrt(d2 - r * r);
    }

    private sphereApplyMatrix4(center: Vertex, radius: number, matrix: THREE.Matrix4) {
        radius = radius * matrix.getMaxScaleOnAxis();
        return {center: Vertex.applyMatrix4(center, matrix.elements), radius: radius};
    }

    private isMeshletVisible(meshlet: Meshlet, meshletMatrixWorld: THREE.Matrix4, cameraMatrixWorld: THREE.Matrix4, screenHeight: number): boolean {
        // const completeProj = new THREE.Matrix4().multiplyMatrices(cameraMatrixWorld, meshletMatrixWorld);
        const completeProj = this.tempMatrix.multiplyMatrices(cameraMatrixWorld, meshletMatrixWorld);

        const projectedBounds = this.sphereApplyMatrix4(
            meshlet.boundingVolume.center, 
            Math.max(meshlet.clusterError, 10e-10),
            completeProj
        )

        const clusterError = this.projectErrorToScreen(projectedBounds.center, projectedBounds.radius, screenHeight);


        if (!meshlet.parentBoundingVolume) console.log(meshlet)

        const parentProjectedBounds = this.sphereApplyMatrix4(
            meshlet.parentBoundingVolume.center, 
            Math.max(meshlet.parentError, 10e-10),
            completeProj
        )

        const parentError = this.projectErrorToScreen(parentProjectedBounds.center, parentProjectedBounds.radius, screenHeight);

        const errorThreshold = 0.1;
        const visible = clusterError <= errorThreshold && parentError > errorThreshold;

        return visible;
    }

    private traverseMeshlets(meshlet: Meshlet, fn: (meshlet: Meshlet) => boolean, visited: {[key: string]: boolean} = {}) {
        if (visited[meshlet.id] === true) return;

        visited[meshlet.id] = true;
        const shouldContinue = fn(meshlet);
        if (!shouldContinue) return;

        for (let child of meshlet.parents) {
            this.traverseMeshlets(child, fn, visited);
        }
    }

    private render(renderer: THREE.WebGLRenderer, camera: THREE.Camera) {

        const screenHeight = renderer.domElement.height;
        camera.updateMatrixWorld();
        const cameraMatrixWorld = camera.matrixWorldInverse;


        let checks = 0;
        let i = 0;
        let j = 0;
        for (let meshletMatrix of this.meshletMatrices) {
            this.traverseMeshlets(this.rootMeshlet, meshlet => {
                const isVisible = this.isMeshletVisible(meshlet, meshletMatrix, cameraMatrixWorld, screenHeight);
                if (isVisible) {
                    const processedMeshlet = this.meshletsProcessed.get(meshlet);
                    if (!processedMeshlet) throw Error("WHHATTT");

                    this.indicesAttribute.array[i] = processedMeshlet.vertexOffset / 3;
                    
                    this.localPositionAttribute.array[j + 0] = meshletMatrix.elements[12];
                    this.localPositionAttribute.array[j + 1] = meshletMatrix.elements[13];
                    this.localPositionAttribute.array[j + 2] = meshletMatrix.elements[14];

                    i++;
                    j+=3;
                }

                checks++;
    
                return !isVisible;
            })
        }

        this.indicesAttribute.needsUpdate = true;
        this.localPositionAttribute.needsUpdate = true;
        this.instancedGeometry.instanceCount = i;

        // console.log("checks", checks)
    }

    private meshletToNonIndexedVertices(meshlet: Meshlet): NonIndexedMeshlet {
        const g = new THREE.BufferGeometry();
        g.setAttribute("position", new THREE.Float32BufferAttribute(meshlet.vertices_raw, 3));
        g.setIndex(new THREE.Uint32BufferAttribute(meshlet.indices_raw, 1));
        const nonIndexed = g.toNonIndexed();
        const v = new Float32Array(1152);
        v.set(nonIndexed.getAttribute("position").array, 0);

        return {
            meshlet: meshlet,
            vertices: v
        }
    }

    private createVerticesTexture(meshlets: NonIndexedMeshlet[]): THREE.DataTexture {
        let vertices: number[] = [];

        for (let meshlet of meshlets) {
            const v = new Float32Array(1152);
            v.set(meshlet.vertices, 0);
            vertices.push(...v);
        }
        let verticesPacked: number[][] = [];
        for (let i = 0; i < vertices.length; i+=3) {
            verticesPacked.push([vertices[i + 0], vertices[i + 1], vertices[i + 2], 0]);
        }

        const size = MeshletObject3D.VERTICES_TEXTURE_SIZE;
        const buffer = new Float32Array(size * size * 4);

        buffer.set(verticesPacked.flat(), 0);
        const texture = new THREE.DataTexture(
            buffer,
            size, size,
            THREE.RGBAFormat,
            THREE.FloatType
        );
        texture.needsUpdate = true;
        texture.generateMipmaps = false;

        return texture;
    }

    public addMeshletAtPosition(position: THREE.Vector3) {
        const tempMesh = new THREE.Object3D();

        tempMesh.position.copy(position);
        tempMesh.updateMatrixWorld();
        this.meshletMatrices.push(tempMesh.matrixWorld.clone());



        this.localPositionAttribute = new THREE.InstancedBufferAttribute(new Float32Array(this.meshlets.length * this.meshletMatrices.length * 3), 3);
        this.instancedGeometry.setAttribute('localPosition', this.localPositionAttribute);
        this.localPositionAttribute.usage = THREE.StaticDrawUsage;

        this.indicesAttribute = new THREE.InstancedBufferAttribute(new Float32Array(this.meshlets.length * this.meshletMatrices.length), 1);
        this.instancedGeometry.setAttribute('index', this.indicesAttribute);
        this.indicesAttribute.usage = THREE.StaticDrawUsage;
    }
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: METISWrapper.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 5532 bytes

```
import * as METIS from "./metis-5.2.1/metis.js";
import { WASMHelper, WASMPointer } from "./utils/WasmHelper.js";

export class METISWrapper {
    private static METIS;

    private static async load() {
        if (!METISWrapper.METIS) {
            METISWrapper.METIS = await METIS.default();
        }
    }

    public static async partition(groups: number[][], nparts: number): Promise<number[][]> {
        await METISWrapper.load();

        // From: pymetis
        function _prepare_graph(adjacency: number[][]) {
            function assert(condition: boolean) {
                if (!condition) throw Error("assert");
            }

            let xadj: number[] = [0]
            let adjncy: number[] = []

            for (let i = 0; i < adjacency.length; i++) {
                let adj = adjacency[i];
                if (adj !== null && adj.length) {
                    assert(Math.max(...adj) < adjacency.length)
                }
                adjncy.push(...adj);
                xadj.push(adjncy.length)
            }

            return [xadj, adjncy]
        }

        const [_xadj, _adjncy] = _prepare_graph(groups);

        // console.log("_xadj", _xadj);
        // console.log("_adjncy", _adjncy);
        // console.log("nparts", nparts);

        const objval = new WASMPointer(new Uint32Array(1), "out");
        const parts = new WASMPointer(new Uint32Array(_xadj.length - 1), "out");

        // console.log("_xadj", _xadj);
        // console.log("edge_weights", edge_weights);
        // throw Error("ERG")

        const options_array = new Int32Array(40);
        options_array.fill(-1);

        // options_array[0] = // METIS_OPTION_PTYPE,
        // options_array[1] = 0 // METIS_OPTION_OBJTYPE,
        // options_array[2] = // METIS_OPTION_CTYPE,
        // options_array[3] = // METIS_OPTION_IPTYPE,
        // options_array[4] = // METIS_OPTION_RTYPE,
        // options_array[5] = // METIS_OPTION_DBGLVL,
        // options_array[6] = // METIS_OPTION_NIPARTS,
        // options_array[7] = // METIS_OPTION_NITER,
        // options_array[8] = // METIS_OPTION_NCUTS,
        // options_array[9] = // METIS_OPTION_SEED,
        // options_array[10] = // METIS_OPTION_ONDISK,
        // options_array[11] = // METIS_OPTION_MINCONN,
        // options_array[12] = 1// METIS_OPTION_CONTIG,
        // options_array[13] = // METIS_OPTION_COMPRESS,
        // options_array[14] = 1// METIS_OPTION_CCORDER,
        // options_array[15] = // METIS_OPTION_PFACTOR,
        // options_array[16] = // METIS_OPTION_NSEPS,
        // options_array[17] = // METIS_OPTION_UFACTOR,
        // options_array[18] = 0 // METIS_OPTION_NUMBERING,
        // options_array[19] = // METIS_OPTION_DROPEDGES,
        // options_array[20] = // METIS_OPTION_NO2HOP,
        // options_array[21] = // METIS_OPTION_TWOHOP,
        // options_array[22] = // METIS_OPTION_FAST,

        // options[METIS_OPTION_OBJTYPE] = 0 // METIS_OBJTYPE_CUT;
        // options[METIS_OPTION_CCORDER] = 1; // identify connected components first
        // options[METIS_OPTION_NUMBERING] = 0;

        
        WASMHelper.call(METISWrapper.METIS, "METIS_PartGraphKway", "number", 
            new WASMPointer(new Int32Array([_xadj.length - 1])), // nvtxs
            new WASMPointer(new Int32Array([1])),                // ncon
            new WASMPointer(new Int32Array(_xadj)),            // xadj
            new WASMPointer(new Int32Array(_adjncy)),          // adjncy
            null,                                              // vwgt
            null,                                              // vsize
            null,                                              // adjwgt
            new WASMPointer(new Int32Array([nparts])),           // nparts
            null,                                              // tpwgts
            null,                                              // ubvec
            new WASMPointer(options_array),                    // options
            objval,                                            // objval
            parts,                                             // part
        )

        // console.log("nvtxs", _xadj.length - 1);
        // console.log("ncon", 1);
        // console.log("xadj", _xadj);
        // console.log("adjncy", _adjncy);
        // console.log("vwgt", null);
        // console.log("vsize", null);
        // console.log("adjwgt", null);
        // console.log("nparts", nparts);
        // console.log("tpwgts", null);
        // console.log("ubvec", null);
        // console.log("_options", null);
        // console.log("objval", objval);
        // console.log("part", parts);
        // // nvtxs,
        // // ncon,
        // // xadj,
        // // adjncy,
        // // vwgt,
        // // vsize,
        // // adjwgt,
        // // nparts,
        // // tpwgts,
        // // ubvec,
        // // _options,
        // // objval,
        // // part,

        const part_num = Math.max(...parts.data);

        const parts_out: number[][] = [];
        for (let i = 0; i <= part_num; i++) {
            const part: number[] = [];

            for (let j = 0; j < parts.data.length; j++) {
                if (parts.data[j] === i) {
                    part.push(j);
                }
            }

            if (part.length > 0) parts_out.push(part);
        }

        return parts_out;
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: OBJLoaderIndexed.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 3882 bytes

```
// From: https://github.com/frenchtoast747/webgl-obj-loader/blob/master/src/mesh.ts
// This method is needed because THREE.OBJLoader creates a triangle soup instead of
// shared vertices. This screws up the mesh for the simplifier.
// Even when using mergeVertices, duplicate vertices are still present even though
// indices are created.
// Note that this method doesn't support uvs, normals, tangents, etc.

interface UnpackedAttrs {
    verts: number[];
    hashindices: { [k: string]: number };
    indices: number[][];
    index: number;
}

export interface OBJMesh {
    vertices: Float32Array,
    indices: Uint32Array
};

export class OBJLoaderIndexed {
    public static* triangulate(elements: string[]) {
        if (elements.length <= 3) {
            yield elements;
        } else if (elements.length === 4) {
            yield [elements[0], elements[1], elements[2]];
            yield [elements[2], elements[3], elements[0]];
        } else {
            for (let i = 1; i < elements.length - 1; i++) {
                yield [elements[0], elements[i], elements[i + 1]];
            }
        }
    }

    public static load(url: string, callback: (contents: OBJMesh) => void) {
        fetch(url).then(response => response.text()).then(contents => callback(OBJLoaderIndexed.parse(contents)));
    }

    public static parse(contents: string): OBJMesh {
        const indices = [];

        const verts: string[] = [];
        let currentMaterialIndex = -1;
        let currentObjectByMaterialIndex = 0;
        // unpacking stuff
        const unpacked: UnpackedAttrs = {
            verts: [],
            hashindices: {},
            indices: [[]],
            index: 0,
        };

        const VERTEX_RE = /^v\s/;
        const FACE_RE = /^f\s/;
        const WHITESPACE_RE = /\s+/;

        // array of lines separated by the newline
        const lines = contents.split("\n");

        for (let line of lines) {
            line = line.trim();
            if (!line || line.startsWith("#")) {
                continue;
            }
            const elements = line.split(WHITESPACE_RE);
            elements.shift();

            if (VERTEX_RE.test(line)) {
                verts.push(...elements);
            } else if (FACE_RE.test(line)) {
                const triangles = OBJLoaderIndexed.triangulate(elements);
                for (const triangle of triangles) {
                    for (let j = 0, eleLen = triangle.length; j < eleLen; j++) {
                        const hash = triangle[j] + "," + currentMaterialIndex;
                        if (hash in unpacked.hashindices) {
                            unpacked.indices[currentObjectByMaterialIndex].push(unpacked.hashindices[hash]);
                        } else {
                            const vertex = triangle[j].split("/");
                            
                            // Vertex position
                            unpacked.verts.push(+verts[(+vertex[0] - 1) * 3 + 0]);
                            unpacked.verts.push(+verts[(+vertex[0] - 1) * 3 + 1]);
                            unpacked.verts.push(+verts[(+vertex[0] - 1) * 3 + 2]);
                            // add the newly created Vertex to the list of indices
                            unpacked.hashindices[hash] = unpacked.index;
                            unpacked.indices[currentObjectByMaterialIndex].push(unpacked.hashindices[hash]);
                            // increment the counter
                            unpacked.index += 1;
                        }
                    }
                }
            }
        }

        return {
            vertices: new Float32Array(unpacked.verts),
            indices: new Uint32Array(unpacked.indices[currentObjectByMaterialIndex])
        };
    }
}

```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: utils\MeshletBuilder.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 2637 bytes

```
import { MeshoptMeshlet } from "./MeshletCreator";
import { WASMHelper, WASMPointer } from "./WasmHelper";
import MeshOptimizerModule from "./meshoptimizer";

export class MeshletBuilder {
    public static meshoptimizer_clusterize;

    private static async load() {
        if (!MeshletBuilder.meshoptimizer_clusterize) {
            MeshletBuilder.meshoptimizer_clusterize = await MeshOptimizerModule();
        }
    }

    public static async build(vertices: Float32Array, indices: Uint32Array, max_vertices: number, max_triangles: number, cone_weight: number): Promise<{
        meshlet_count: number,
        meshlets_result: MeshoptMeshlet[],
        meshlet_vertices_result: Uint32Array,
        meshlet_triangles_result: Uint8Array
    }> {

        await MeshletBuilder.load();

        const MeshOptmizer = MeshletBuilder.meshoptimizer_clusterize;

        function rebuildMeshlets(data) {
            let meshlets: MeshoptMeshlet[] = [];

            for (let i = 0; i < data.length; i += 4) {
                meshlets.push({
                    vertex_offset: data[i + 0],
                    triangle_offset: data[i + 1],
                    vertex_count: data[i + 2],
                    triangle_count: data[i + 3]
                })
            }

            return meshlets;
        }

        const max_meshlets = WASMHelper.call(MeshOptmizer, "meshopt_buildMeshletsBound", "number", indices.length, max_vertices, max_triangles);



        const meshlets = new WASMPointer(new Uint32Array(max_meshlets * 4), "out");
        const meshlet_vertices = new WASMPointer(new Uint32Array(max_meshlets * max_vertices), "out");
        const meshlet_triangles = new WASMPointer(new Uint8Array(max_meshlets * max_triangles * 3), "out");

        const meshletCount = WASMHelper.call(MeshOptmizer, "meshopt_buildMeshlets", "number", 
            meshlets,
            meshlet_vertices,
            meshlet_triangles,
            new WASMPointer(Uint32Array.from(indices)),
            indices.length,
            new WASMPointer(Float32Array.from(vertices)),
            vertices.length,
            3 * Float32Array.BYTES_PER_ELEMENT,
            max_vertices,
            max_triangles,
            cone_weight
        );

        const meshlets_result = rebuildMeshlets(meshlets.data).splice(0, meshletCount);

        return {
            meshlet_count: meshletCount,
            meshlets_result: meshlets_result,
            meshlet_vertices_result: meshlet_vertices.data,
            meshlet_triangles_result: meshlet_triangles.data
        }
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: utils\MeshletCleaner.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1951 bytes

```
import { Meshlet } from "../Meshlet";
import { WASMHelper, WASMPointer } from "./WasmHelper";

import MeshOptimizerModule from "./meshoptimizer";

// From: THREE.js
export class MeshletCleaner {
    public static meshoptimizer;

    private static async load() {
        if (!MeshletCleaner.meshoptimizer) {
            MeshletCleaner.meshoptimizer = await MeshOptimizerModule();
        }
    }

    public static async clean(meshlet: Meshlet): Promise<Meshlet> {
        await MeshletCleaner.load();

        const MeshOptmizer = MeshletCleaner.meshoptimizer;

        const remap = new WASMPointer(new Uint32Array(meshlet.indices_raw.length * 3), "out");
        const indices = new WASMPointer(new Uint32Array(meshlet.indices_raw), "in");
        const vertices = new WASMPointer(new Float32Array(meshlet.vertices_raw), "in");

        const vertex_count = WASMHelper.call(MeshOptmizer, "meshopt_generateVertexRemap", "number", 
            remap,
            indices,
            meshlet.indices_raw.length,
            vertices,
            meshlet.vertices_raw.length,
            3 * Float32Array.BYTES_PER_ELEMENT
        );
        
        const indices_remapped = new WASMPointer(new Uint32Array(meshlet.indices_raw.length), "out");
        WASMHelper.call(MeshOptmizer, "meshopt_remapIndexBuffer", "number", 
            indices_remapped,
            indices,
            meshlet.indices_raw.length,
            remap
        );
        
        const vertices_remapped = new WASMPointer(new Float32Array(vertex_count * 3), "out");
        WASMHelper.call(MeshOptmizer, "meshopt_remapVertexBuffer", "number", 
            vertices_remapped,
            vertices,
            meshlet.vertices_raw.length,
            3 * Float32Array.BYTES_PER_ELEMENT,
            remap
        );

        const m = new Meshlet(vertices_remapped.data, indices_remapped.data);
        return m;
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: utils\MeshletCreator.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 3353 bytes

```
import { Meshlet } from "../Meshlet";
import { MeshletBuilder } from "./MeshletBuilder";

export interface MeshoptMeshlet {
    triangle_offset: number;
    triangle_count: number;
    vertex_offset: number;
    vertex_count: number;
}

interface MeshletBuildOutput {
    meshlets_count: number;
    meshlets_result: MeshoptMeshlet[];
    meshlet_vertices_result: Uint32Array;
    meshlet_triangles_result: Uint8Array;
}

export class MeshletCreator {
    private static max_vertices = 255;
    private static max_triangles = 128;
    private static cone_weight = 0.0;

    public static async buildFromWasm(vertices: Float32Array, indices: Uint32Array): Promise<MeshletBuildOutput> {
        const max_vertices = MeshletCreator.max_vertices;
        const max_triangles = MeshletCreator.max_triangles;
        const cone_weight = MeshletCreator.cone_weight;

        const output = await MeshletBuilder.build(vertices, indices, max_vertices, max_triangles, cone_weight)
        return {
            meshlets_count: output.meshlet_count,
            meshlets_result: output.meshlets_result.slice(0, output.meshlet_count),
            meshlet_vertices_result: output.meshlet_vertices_result,
            meshlet_triangles_result: output.meshlet_triangles_result
        }
    }

    public static buildMeshletsFromBuildOutput(vertices: Float32Array, output: MeshletBuildOutput): Meshlet[] {
        let meshlets: Meshlet[] = [];

        for (let i = 0; i < output.meshlets_count; i++) {
            const meshlet = output.meshlets_result[i];

            let meshlet_positions: number[] = [];
            let meshlet_indices: number[] = [];

            for (let v = 0; v < meshlet.vertex_count; ++v) {
                const o = 3 * output.meshlet_vertices_result[meshlet.vertex_offset + v];
                const x = vertices[o];
                const y = vertices[o + 1];
                const z = vertices[o + 2];

                meshlet_positions.push(x);
                meshlet_positions.push(y);
                meshlet_positions.push(z);
            }
            for (let t = 0; t < meshlet.triangle_count; ++t) {
                const o = meshlet.triangle_offset + 3 * t;
                meshlet_indices.push(output.meshlet_triangles_result[o + 0]);
                meshlet_indices.push(output.meshlet_triangles_result[o + 1]);
                meshlet_indices.push(output.meshlet_triangles_result[o + 2]);
            }

            meshlets.push(new Meshlet(meshlet_positions, meshlet_indices));
        }
        return meshlets;
    }

    public static async build(vertices: Float32Array, indices: Uint32Array, max_vertices: number, max_triangles: number) {
        const cone_weight = MeshletCreator.cone_weight;

        const output = await MeshletBuilder.build(vertices, indices, max_vertices, max_triangles, cone_weight)
        const m = {
            meshlets_count: output.meshlet_count,
            meshlets_result: output.meshlets_result.slice(0, output.meshlet_count),
            meshlet_vertices_result: output.meshlet_vertices_result,
            meshlet_triangles_result: output.meshlet_triangles_result
        }


        const meshlets = MeshletCreator.buildMeshletsFromBuildOutput(vertices, m);
        
        return meshlets;
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: utils\MeshletSimplifier.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 2083 bytes

```
import { WASMHelper, WASMPointer } from "./WasmHelper";

import MeshOptimizerModule from "./meshoptimizer";
import { Meshlet } from "../Meshlet";

export interface SimplificationResult {
    result_error: number;
    meshlet: Meshlet;
};

export class MeshletSimplifier_wasm {
    public static meshoptimizer_clusterize;

    private static async load() {
        if (!MeshletSimplifier_wasm.meshoptimizer_clusterize) {
            MeshletSimplifier_wasm.meshoptimizer_clusterize = await MeshOptimizerModule();
        }
    }

    public static async simplify(meshlet: Meshlet, target_count: number): Promise<SimplificationResult> {

        await MeshletSimplifier_wasm.load();

        const MeshOptmizer = MeshletSimplifier_wasm.meshoptimizer_clusterize;

        const destination = new WASMPointer(new Uint32Array(meshlet.indices_raw.length), "out");
        const result_error = new WASMPointer(new Float32Array(1), "out");
        
        const simplified_index_count = WASMHelper.call(MeshOptmizer, "meshopt_simplify", "number",
            destination, // unsigned int* destination,
            new WASMPointer(new Uint32Array(meshlet.indices_raw)), // const unsigned int* indices,
            meshlet.indices_raw.length, // size_t index_count,
            new WASMPointer(new Float32Array(meshlet.vertices_raw)), // const float* vertex_positions,
            meshlet.vertices_raw.length, // size_t vertex_count,
            3 * Float32Array.BYTES_PER_ELEMENT, // size_t vertex_positions_stride,
            target_count, // size_t target_index_count,
            0.05, // float target_error, Should be 0.01 but cant reach 128 triangles with it
            1, // unsigned int options, preserve borders
            result_error, // float* result_error
        );

        const destination_resized = destination.data.slice(0, simplified_index_count) as Uint32Array;

        return {
            result_error: result_error.data[0],
            meshlet: new Meshlet(meshlet.vertices_raw, destination_resized)
        }
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: utils\MeshSimplifyScale.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 1074 bytes

```
import { Meshlet } from "../Meshlet";
import { WASMHelper, WASMPointer } from "./WasmHelper";

import MeshOptimizerModule from "./meshoptimizer";

// From: THREE.js
export class MeshSimplifyScale {
    public static meshoptimizer;

    private static async load() {
        if (!MeshSimplifyScale.meshoptimizer) {
            MeshSimplifyScale.meshoptimizer = await MeshOptimizerModule();
        }
    }

    public static async scaleError(meshlet: Meshlet): Promise<number> {
        await MeshSimplifyScale.load();

        const MeshOptmizer = MeshSimplifyScale.meshoptimizer;


        const vertices = new WASMPointer(new Float32Array(meshlet.vertices_raw), "in");

        // float meshopt_simplifyScale(const float* vertex_positions, size_t vertex_count, size_t vertex_positions_stride)
        const scale = WASMHelper.call(MeshOptmizer, "meshopt_simplifyScale", "number", 
            vertices,
            meshlet.vertices_raw.length,
            3 * Float32Array.BYTES_PER_ELEMENT
        );
        
        return scale;
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

## File: utils\WasmHelper.ts

- **Encoding:** utf-8
- **Binary:** False
- **Size:** 4850 bytes

```
export type ArrayType = Uint8Array | Uint16Array | Uint32Array | Int8Array | Int16Array | Int32Array | Float32Array | Float64Array;

export class WASMPointer {
    public data: ArrayType;
    public ptr: number | null;
    public type: "in" | "out";

    constructor(data: ArrayType, type: "in" | "out" = "in") {
        this.data = data;
        this.ptr = null;
        this.type = type;
    }
}

export class WASMHelper {
    public static TYPES = {
        i8: { array: Int8Array, heap: "HEAP8" },
        i16: { array: Int16Array, heap: "HEAP16" },
        i32: { array: Int32Array, heap: "HEAP32" },
        f32: { array: Float32Array, heap: "HEAPF32" },
        f64: { array: Float64Array, heap: "HEAPF64" },
        u8: { array: Uint8Array, heap: "HEAPU8" },
        u16: { array: Uint16Array, heap: "HEAPU16" },
        u32: { array: Uint32Array, heap: "HEAPU32" }
    };

    public static getTypeForArray(array: ArrayType) {
        if (array instanceof Int8Array) return this.TYPES.i8;
        else if (array instanceof Int16Array) return this.TYPES.i16;
        else if (array instanceof Int32Array) return this.TYPES.i32;
        else if (array instanceof Uint8Array) return this.TYPES.u8;
        else if (array instanceof Uint16Array) return this.TYPES.u16;
        else if (array instanceof Uint32Array) return this.TYPES.u32;
        else if (array instanceof Float32Array) return this.TYPES.f32;
        else if (array instanceof Float64Array) return this.TYPES.f64;

        console.log(array)
        throw Error("Array has no type");
    }

    public static transferNumberArrayToHeap(module, array): number {
        const type = this.getTypeForArray(array);
        const typedArray = type.array.from(array);
        const heapPointer = module._malloc(
            typedArray.length * typedArray.BYTES_PER_ELEMENT
        );

        module[type.heap].set(typedArray, heapPointer >> 2);

        return heapPointer;
    }

    public static getDataFromHeapU8(module, address: number, type, length: number) {
        return module[type.heap].slice(address, address + length);
    }

    public static getDataFromHeap(module, address: number, type, length: number) {
        return module[type.heap].slice(address >> 2, (address >> 2) + length);
    }

    public static getArgumentTypes(args: any[]): string[] {
        let argTypes: string[] = [];
        for (let i = 0; i < args.length; i++) {
            const arg = args[i];
            if (arg instanceof Uint8Array) argTypes.push("number");
            else if (arg instanceof Uint16Array) argTypes.push("number");
            else if (arg instanceof Uint32Array) argTypes.push("number");
            else if (arg instanceof Int8Array) argTypes.push("number");
            else if (arg instanceof Int16Array) argTypes.push("number");
            else if (arg instanceof Int32Array) argTypes.push("number");
            else if (arg instanceof Float32Array) argTypes.push("number");
            else if (arg instanceof Float64Array) argTypes.push("number");
            else if (typeof arg === "string") argTypes.push("string");
            else argTypes.push("number");
        }
        return argTypes;
    }

    private static transferArguments(module, args: any[]) {
        let method_args: any[] = [];
        for (let i = 0; i < args.length; i++) {
            const arg = args[i];
            if (arg instanceof WASMPointer) {
                arg.ptr = WASMHelper.transferNumberArrayToHeap(module, arg.data);
                method_args.push(arg.ptr);
            }
            else method_args.push(args[i]);
        }
        return method_args;
    }

    private static getOutputArguments(module, args: any[]) {
        for (let i = 0; i < args.length; i++) {
            const arg = args[i];
            if (!(arg instanceof WASMPointer)) continue;
            if (arg.ptr === null) continue;
            if (arg.type === "in") continue;
            const type = WASMHelper.getTypeForArray(arg.data);
            if (type === this.TYPES.u8) {
                arg.data = WASMHelper.getDataFromHeapU8(module, arg.ptr, type, arg.data.length);
            }
            else {
                arg.data = WASMHelper.getDataFromHeap(module, arg.ptr, type, arg.data.length);
            }
        }
    }

    public static call(module, method: string, returnType: string, ...args: any[]) {
        let method_args = WASMHelper.transferArguments(module, args);
        const method_arg_types = WASMHelper.getArgumentTypes(args);
        const ret = module.ccall(method, 
            returnType, 
            method_arg_types,
            method_args
        );

        WASMHelper.getOutputArguments(module, args);

        return ret;
    }
}
```

<!-- CODEZIPPER_FILE_SEPARATOR -->

<!-- CODEZIPPER_CONTENT_END -->