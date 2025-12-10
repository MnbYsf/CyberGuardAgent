import os
import shutil
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Import functions from existing modules
from Consumer import detect_malware, display_file_info
from Converter import convert_exe_to_image, get_width

# Initialize FastAPI app
app = FastAPI(
    title="Malware Detection API",
    description="API for detecting malware in executable files using deep learning",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add request logging middleware for debugging
@app.middleware("http")
async def log_requests(request, call_next):
    print(f"\n{'='*60}")
    print(f"INCOMING REQUEST: {request.method} {request.url.path}")
    print(f"Headers: {dict(request.headers)}")
    print(f"{'='*60}\n")
    response = await call_next(request)
    return response


# Define directories
UPLOAD_DIR = Path("./uploads")
OUTPUT_DIR = Path("./output")
MODEL_PATH = "malware128.h5"

# Create directories if they don't exist
UPLOAD_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)


# Response models
class PredictionDetail(BaseModel):
    class_name: str
    probability: float


class DetectionResult(BaseModel):
    status: str
    predicted_class: str
    confidence: float
    action: str


class AnalysisResponse(BaseModel):
    filename: str
    file_size_bytes: int
    file_size_kb: float
    original_dimensions: str
    resized_dimensions: str
    detection_result: DetectionResult
    top_predictions: list[PredictionDetail]
    image_path: str


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint to verify API is running"""
    model_exists = os.path.exists(MODEL_PATH)
    return {
        "status": "healthy",
        "model_available": model_exists,
        "upload_dir": str(UPLOAD_DIR),
        "output_dir": str(OUTPUT_DIR)
    }


# Main analysis endpoint
@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_file(file: UploadFile = File(...)):
    """
    Analyze an executable file for malware detection.
    
    Args:
        file: Executable file (.exe) to analyze
        
    Returns:
        Analysis results including malware detection status and confidence
    """
    
    # Debug logging
    print(f"DEBUG: Received file upload request")
    print(f"DEBUG: File object: {file}")
    print(f"DEBUG: Filename: {file.filename if file else 'None'}")
    print(f"DEBUG: Content type: {file.content_type if file else 'None'}")
    
    # Validate file type
    if not file.filename.endswith('.exe'):
        raise HTTPException(
            status_code=400,
            detail="Only .exe files are supported"
        )
    
    # Generate temporary file path
    temp_file_path = UPLOAD_DIR / file.filename
    
    try:
        # Save uploaded file
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Get file information
        file_size = os.path.getsize(temp_file_path)
        width = get_width(file_size)
        height = (file_size + width - 1) // width
        
        # Convert executable to image
        convert_exe_to_image(str(temp_file_path), str(OUTPUT_DIR))
        
        # Generate image path
        image_filename = file.filename + ".png"
        image_path = OUTPUT_DIR / image_filename
        
        if not image_path.exists():
            raise HTTPException(
                status_code=500,
                detail="Image conversion failed"
            )
        
        # Perform malware detection
        detection_result = detect_malware(str(image_path), MODEL_PATH)
        
        if detection_result is None:
            raise HTTPException(
                status_code=500,
                detail="Malware detection failed"
            )
        
        # Define malware types for top predictions
        malware_types = [
            "Adialer.C", "Agent.FYI", "Allaple.A", "Allaple.L", "Alueron.gen!J",
            "Autorun.K", "C2LOP.P", "C2LOP.gen!g", "Dialplatform.B", "Dontovo.A",
            "Fakerean", "Instantaccess", "Lolyda.AA1", "Lolyda.AA2", "Lolyda.AA3",
            "Lolyda.AT", "Malex.gen!J", "Obfuscator.AD", "Rbot!gen", "Skintrim.N",
            "Swizzor.gen!E", "Swizzor.gen!I", "VB.AT", "Wintrim.BX", "Yuner.A"
        ]
        
        # Get top 5 predictions
        all_probs = detection_result['all_probabilities']
        class_probs = [
            (malware_types[i], float(all_probs[i])) 
            for i in range(len(malware_types))
        ]
        class_probs.sort(key=lambda x: x[1], reverse=True)
        top_5 = class_probs[:5]
        
        # Prepare response
        response = AnalysisResponse(
            filename=file.filename,
            file_size_bytes=file_size,
            file_size_kb=round(file_size / 1024, 2),
            original_dimensions=f"{width}x{height}",
            resized_dimensions="128x128",
            detection_result=DetectionResult(
                status=detection_result['status'],
                predicted_class=detection_result['predicted_class'],
                confidence=detection_result['confidence'],
                action=detection_result['action']
            ),
            top_predictions=[
                PredictionDetail(class_name=name, probability=prob)
                for name, prob in top_5
            ],
            image_path=str(image_path)
        )
        
        return response
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
        
    except Exception as e:
        # Handle unexpected errors
        raise HTTPException(
            status_code=500,
            detail=f"An error occurred during analysis: {str(e)}"
        )
        
    finally:
        # Clean up uploaded file
        if temp_file_path.exists():
            try:
                os.remove(temp_file_path)
            except Exception as e:
                print(f"Warning: Could not remove temporary file {temp_file_path}: {e}")


# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Malware Detection API",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "analyze": "/analyze (POST)",
            "docs": "/docs"
        }
    }


if __name__ == "__main__":
    print("=" * 60)
    print("Starting Malware Detection API")
    print("=" * 60)
    print(f"Upload Directory: {UPLOAD_DIR.absolute()}")
    print(f"Output Directory: {OUTPUT_DIR.absolute()}")
    print(f"Model Path: {MODEL_PATH}")
    print("=" * 60)
    
    # Run the server
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8083,
        log_level="info"
    )
