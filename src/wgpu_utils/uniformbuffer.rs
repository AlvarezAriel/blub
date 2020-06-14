use std::marker::PhantomData;

pub struct UniformBuffer<Content> {
    buffer: wgpu::Buffer,
    content: PhantomData<Content>,
}

impl<Content: bytemuck::Pod> UniformBuffer<Content> {
    fn name() -> &'static str {
        let type_name = std::any::type_name::<Content>();
        let pos = type_name.rfind(':').unwrap();
        &type_name[(pos + 1)..]
    }

    pub fn new(device: &wgpu::Device) -> UniformBuffer<Content> {
        let buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some(&format!("UniformBuffer: {}", Self::name())),
            size: std::mem::size_of::<Content>() as u64,
            usage: wgpu::BufferUsage::UNIFORM | wgpu::BufferUsage::COPY_DST,
            mapped_at_creation: false,
        });

        UniformBuffer {
            buffer,
            content: PhantomData,
        }
    }

    pub fn new_with_data(device: &wgpu::Device, initial_content: &Content) -> UniformBuffer<Content> {
        let buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some(&format!("UniformBuffer: {}", Self::name())),
            size: std::mem::size_of::<Content>() as u64,
            usage: wgpu::BufferUsage::UNIFORM | wgpu::BufferUsage::COPY_DST,
            mapped_at_creation: true,
        });

        let mapped_memory = buffer.slice(..);
        mapped_memory.get_mapped_range_mut().clone_from_slice(bytemuck::bytes_of(initial_content));
        buffer.unmap();

        UniformBuffer {
            buffer,
            content: PhantomData,
        }
    }

    pub fn update_content(&self, queue: &wgpu::Queue, content: Content) {
        queue.write_buffer(&self.buffer, 0, bytemuck::bytes_of(&content));
    }

    pub fn binding_resource(&self) -> wgpu::BindingResource {
        wgpu::BindingResource::Buffer(self.buffer.slice(..))
    }
}

#[derive(Clone, Copy)]
#[allow(dead_code)]
pub struct PaddedVector3 {
    vector: cgmath::Vector3<f32>,
    padding: f32,
}
impl From<cgmath::Vector3<f32>> for PaddedVector3 {
    fn from(vector: cgmath::Vector3<f32>) -> Self {
        PaddedVector3 { vector, padding: 0.0 }
    }
}

#[derive(Clone, Copy)]
#[allow(dead_code)]
pub struct PaddedPoint3 {
    point: cgmath::Point3<f32>,
    padding: f32,
}
impl From<cgmath::Point3<f32>> for PaddedPoint3 {
    fn from(point: cgmath::Point3<f32>) -> Self {
        PaddedPoint3 { point, padding: 1.0 }
    }
}
