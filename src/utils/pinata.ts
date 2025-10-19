import axios from 'axios'

const PINATA_API_URL = 'https://api.pinata.cloud'
const PINATA_GATEWAY_URL = import.meta.env.VITE_PINATA_GATEWAY_URL || 'https://gateway.pinata.cloud/ipfs/'

// Pinata configuration
const pinataConfig = {
  headers: {
    'Authorization': `Bearer ${import.meta.env.PINATA_JWT}`,
    'Content-Type': 'application/json',
  }
}

export interface PinataUploadResponse {
  IpfsHash: string
  PinSize: number
  Timestamp: string
}

export interface PropertyMetadata {
  name: string
  description: string
  image: string
  attributes: Array<{
    trait_type: string
    value: string | number
    display_type?: string
  }>
  spv_registry_id: string
  legal_documents_hash?: string
  location: {
    coordinates: [number, number]
    address: string
    city: string
    state: string
    country: string
  }
  verification: {
    status: 'pending' | 'verified' | 'rejected'
    verifier_address?: string
    verification_date?: number
    compliance_score?: number
  }
}

/**
 * Upload JSON metadata to IPFS via Pinata
 */
export async function uploadMetadataToIPFS(metadata: PropertyMetadata): Promise<string> {
  try {
    const response = await axios.post(
      `${PINATA_API_URL}/pinning/pinJSONToIPFS`,
      {
        pinataContent: metadata,
        pinataMetadata: {
          name: `property-metadata-${Date.now()}`,
          keyvalues: {
            type: 'property-metadata',
            property_name: metadata.name
          }
        }
      },
      pinataConfig
    )

    return response.data.IpfsHash
  } catch (error) {
    console.error('Error uploading metadata to IPFS:', error)
    throw new Error('Failed to upload metadata to IPFS')
  }
}

/**
 * Upload file to IPFS via Pinata
 */
export async function uploadFileToIPFS(file: File): Promise<string> {
  try {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('pinataMetadata', JSON.stringify({
      name: `${file.name}-${Date.now()}`,
      keyvalues: {
        type: 'property-document',
        filename: file.name
      }
    }))

    const response = await axios.post(
      `${PINATA_API_URL}/pinning/pinFileToIPFS`,
      formData,
      {
        headers: {
          'Authorization': `Bearer ${import.meta.env.PINATA_JWT}`,
          'Content-Type': 'multipart/form-data',
        }
      }
    )

    return response.data.IpfsHash
  } catch (error) {
    console.error('Error uploading file to IPFS:', error)
    throw new Error('Failed to upload file to IPFS')
  }
}

/**
 * Get IPFS content URL
 */
export function getIPFSUrl(hash: string): string {
  return `${PINATA_GATEWAY_URL}${hash}`
}

/**
 * Fetch metadata from IPFS
 */
export async function fetchMetadataFromIPFS(hash: string): Promise<PropertyMetadata> {
  try {
    const response = await axios.get(getIPFSUrl(hash))
    return response.data
  } catch (error) {
    console.error('Error fetching metadata from IPFS:', error)
    throw new Error('Failed to fetch metadata from IPFS')
  }
}

/**
 * Upload multiple images and return their IPFS hashes
 */
export async function uploadImagesToIPFS(images: File[]): Promise<string[]> {
  const uploadPromises = images.map(image => uploadFileToIPFS(image))
  return Promise.all(uploadPromises)
}

/**
 * Create optimized property metadata with IPFS image URLs
 */
export async function createPropertyMetadata(
  propertyData: Omit<PropertyMetadata, 'image'>,
  primaryImage: File,
  additionalImages?: File[]
): Promise<{ metadata: PropertyMetadata; metadataHash: string }> {
  try {
    // Upload primary image
    const primaryImageHash = await uploadFileToIPFS(primaryImage)
    
    // Upload additional images if provided
    let additionalImageHashes: string[] = []
    if (additionalImages && additionalImages.length > 0) {
      additionalImageHashes = await uploadImagesToIPFS(additionalImages)
    }

    // Create complete metadata
    const metadata: PropertyMetadata = {
      ...propertyData,
      image: getIPFSUrl(primaryImageHash),
      attributes: [
        ...propertyData.attributes,
        {
          trait_type: 'Additional Images',
          value: additionalImageHashes.length,
          display_type: 'number'
        }
      ]
    }

    // Add additional images to attributes if present
    if (additionalImageHashes.length > 0) {
      metadata.attributes.push({
        trait_type: 'Image Gallery',
        value: additionalImageHashes.map(hash => getIPFSUrl(hash)).join(',')
      })
    }

    // Upload metadata to IPFS
    const metadataHash = await uploadMetadataToIPFS(metadata)

    return { metadata, metadataHash }
  } catch (error) {
    console.error('Error creating property metadata:', error)
    throw new Error('Failed to create property metadata')
  }
}